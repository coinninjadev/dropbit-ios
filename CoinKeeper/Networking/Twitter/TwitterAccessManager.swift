//
//  TwitterAccessManager.swift
//  DropBit
//
//  Created by BJ Miller on 5/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import PromiseKit
import UIKit
import OAuthSwift

protocol TwitterAccessManagerType: AnyObject {
  func getCurrentTwitterUser() -> Promise<TwitterUser>
  func getCurrentTwitterUser(in context: NSManagedObjectContext) -> Promise<TwitterUser>
  func refreshTwitterAvatar(in context: NSManagedObjectContext) -> Promise<Bool> //did change
  func authorizeAndStoreTwitterCredentials(presentingViewController controller: UIViewController,
                                           in context: NSManagedObjectContext) -> Promise<Void> //TwitterOAuthStorage
  func findTwitterUsers(using term: String, fromViewController controller: UIViewController) -> Promise<[TwitterUser]>
  func defaultFollowingList(fromViewController controller: UIViewController) -> Promise<[TwitterUser]>
  func inflateTwitterUsersIfNeeded(in context: NSManagedObjectContext) -> Promise<Void>

  var uiTestArguments: [UITestArgument] { get set }
}

class TwitterAccessManager: TwitterAccessManagerType {

  /// Any internal- or public-level methods should return dummy values if UI testing
  var uiTestArguments: [UITestArgument] = []

  private let networkManager: NetworkManagerType
  private let persistenceManager: PersistenceManagerType
  private let userIdentifiableManager: UserIdentifiableManagerType
  private let serialQueueManager: SerialQueueManagerType

  private var isNotUITesting: Bool {
    let isUITesting = uiTestArguments.contains(.skipTwitterAuthentication)
    return !isUITesting
  }

  init(networkManager: NetworkManagerType, persistenceManager: PersistenceManagerType,
       userIdentifiableManager: UserIdentifiableManagerType, serialQueueManager: SerialQueueManagerType) {
    self.networkManager = networkManager
    self.persistenceManager = persistenceManager
    self.userIdentifiableManager = userIdentifiableManager
    self.serialQueueManager = serialQueueManager
  }

  func getCurrentTwitterUser(in context: NSManagedObjectContext) -> Promise<TwitterUser> {
    guard isNotUITesting else { return Promise.value(TwitterUser.emptyInstance()) }
    return authorizeAndStoreIfNecessary(in: context)
      .then { self.networkManager.retrieveTwitterUser(with: $0.twitterUserId) }
      .get({ (twitterUser: TwitterUser) in
        try context.performThrowingAndWait {
          let user = CKMUser.find(in: context)
          user?.avatar = twitterUser.profileImageData
          try context.saveRecursively()
        }
      })
  }

  /// default context is viewContext
  func getCurrentTwitterUser() -> Promise<TwitterUser> {
    guard isNotUITesting else { return Promise.value(TwitterUser.emptyInstance()) }
    return getCurrentTwitterUser(in: persistenceManager.viewContext)
  }

  func refreshTwitterAvatar(in context: NSManagedObjectContext) -> Promise<Bool> {
    let originalAvatar = CKMUser.find(in: context)?.avatar
    return getCurrentTwitterUser(in: context)
      .then { twitterUser -> Promise<Bool> in
        let avatarDidChange = twitterUser.profileImageData != originalAvatar
        return Promise.value(avatarDidChange)
    }
  }

  func authorizeAndStoreTwitterCredentials(presentingViewController controller: UIViewController,
                                           in context: NSManagedObjectContext) -> Promise<Void> {
    guard isNotUITesting else { return Promise.value(()) }
    let handler = SafariURLHandler(viewController: controller, oauthSwift: networkManager.twitterOAuthManager)
    networkManager.twitterOAuthManager.authorizeURLHandler = handler

    return authorizeAndStoreIfNecessary(in: context).asVoid()
  }

  func addTwitterUserIdentity(
    credentials: TwitterOAuthStorage,
    in context: NSManagedObjectContext) -> Promise<UserIdentifiable> {
    let userIdentityBody = UserIdentityBody(twitterCredentials: credentials)
    return self.userIdentifiableManager.registerUser(with: userIdentityBody,
                                                     in: context)
  }

  func findTwitterUsers(using term: String, fromViewController controller: UIViewController) -> Promise<[TwitterUser]> {
    guard isNotUITesting else { return Promise.value([TwitterUser.emptyInstance()]) }
    let context = persistenceManager.createBackgroundContext()
    let handler = SafariURLHandler(viewController: controller, oauthSwift: networkManager.twitterOAuthManager)
    networkManager.twitterOAuthManager.authorizeURLHandler = handler
    return authorizeAndStoreIfNecessary(in: context).then { _ in self.networkManager.findTwitterUsers(using: term) }
  }

  func defaultFollowingList(fromViewController controller: UIViewController) -> Promise<[TwitterUser]> {
    guard isNotUITesting else { return Promise.value([TwitterUser.emptyInstance()]) }
    let handler = SafariURLHandler(viewController: controller, oauthSwift: networkManager.twitterOAuthManager)
    networkManager.twitterOAuthManager.authorizeURLHandler = handler
    let context = persistenceManager.createBackgroundContext()
    return authorizeAndStoreTwitterCredentials(presentingViewController: controller,
                                               in: context)
      .then { _ in self.networkManager.defaultFollowingList() }
  }

  func inflateTwitterUsersIfNeeded(in context: NSManagedObjectContext) -> Promise<Void> {
    guard isNotUITesting else { return Promise.value(()) }
    guard persistenceManager.brokers.user.userIsVerified(using: .twitter, in: context) else { return Promise.value(()) }
    let inflatable = CKMTwitterContact.findAllNeedingInflated(in: context)
    guard inflatable.isNotEmpty else { return Promise.value(()) }
    let promises = inflatable.map { ckmTwitterContact -> Promise<Void> in
      return self.networkManager.retrieveTwitterUser(with: ckmTwitterContact.identityHash)
        .get(in: context) { (twitterUser: TwitterUser) in
          var twitterContact = TwitterContact(twitterUser: twitterUser)
          switch ckmTwitterContact.verificationStatus {
          case .notVerified: twitterContact.kind = .generic
          case .verified: twitterContact.kind = .registeredUser
          }
          ckmTwitterContact.configure(with: twitterContact, in: context)
      }.asVoid()
    }
    return when(resolved: promises).asVoid()
  }

  // MARK: private
  private func fetchStoredOauthCredentials(with credentials: TwitterOAuthStorage) -> Promise<TwitterOAuthStorage> {
    let newCredential = OAuthSwiftCredential(consumerKey: twitterOAuth.consumerKey, consumerSecret: twitterOAuth.consumerSecret)
    newCredential.oauthToken = credentials.twitterOAuthToken
    newCredential.oauthTokenSecret = credentials.twitterOAuthTokenSecret
    networkManager.twitterOAuthManager.client = OAuthSwiftClient(credential: newCredential)
    return .value(credentials)
  }

  private func storeTwitterOAuth(_ oauth: TwitterOAuthStorage,
                                 verifyBody: VerifyUserBody,
                                 in context: NSManagedObjectContext) -> Promise<TwitterOAuthStorage> {
    return addTwitterUserIdentity(credentials: oauth, in: context)
      .then { userResponse in return Promise.value((userResponse.id, verifyBody, oauth)) }
      .then(in: context) { userId, body, creds -> Promise<UserResponse> in
        return self.networkManager.verifyUser(id: userId, body: body)
          .get(in: context) { response in
            self.persistenceManager.keychainManager.store(oauthCredentials: creds)
            self.persistenceManager.brokers.user.persistUserId(response.id, in: context)
        }
      }
      .then(in: context) { (response: UserResponse) -> Promise<Void> in
        log.debug("user response: \(response.id)")
        return self.userIdentifiableManager.checkAndPersistVerificationStatus(from: response, in: context)
      }
      .then(in: context) { self.getCurrentTwitterUser(in: context) }
      .then { _ in self.networkManager.getOrCreateLightningAccount() }
      .get(in: context) { lnAccountResponse in
        self.persistenceManager.brokers.lightning.persistAccountResponse(lnAccountResponse, in: context)
        do {
          try context.saveRecursively()
        } catch {
          log.contextSaveError(error)
        }
      }.get { _ in
        self.serialQueueManager.enqueueOptionalIncrementalSync()
      }.map { _ in return oauth }

  }

  private func authorizeAndStoreIfNecessary(in context: NSManagedObjectContext) -> Promise<TwitterOAuthStorage> {
    if let credentials = persistenceManager.keychainManager.oauthCredentials() {
      return fetchStoredOauthCredentials(with: credentials)
    } else {
      return networkManager.authorizeTwitterUser()
        .then(in: context) { creds -> Promise<TwitterOAuthStorage> in
        let maybeReferrer = self.persistenceManager.brokers.user.referredBy
        let verifyBody = VerifyUserBody(twitterCredentials: creds, referrer: maybeReferrer)
        return self.storeTwitterOAuth(creds, verifyBody: verifyBody, in: context)
      }
    }
  }
}
