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
  func authorizedTwitterCredentials(presentingViewController controller: UIViewController) -> Promise<TwitterOAuthStorage>
  func findTwitterUsers(using term: String, fromViewController controller: UIViewController) -> Promise<[TwitterUser]>
  func defaultFollowingList(fromViewController controller: UIViewController) -> Promise<[TwitterUser]>

  var uiTestArguments: [UITestArgument] { get set }
}

class TwitterAccessManager: TwitterAccessManagerType {

  /// Any internal- or public-level methods should return dummy values if UI testing
  var uiTestArguments: [UITestArgument] = []

  private let networkManager: NetworkManagerType
  private let persistenceManager: PersistenceManagerType

  private var isNotUITesting: Bool {
    let isUITesting = uiTestArguments.contains(.skipTwitterAuthentication)
    return !isUITesting
  }

  init(networkManager: NetworkManagerType, persistenceManager: PersistenceManagerType) {
    self.networkManager = networkManager
    self.persistenceManager = persistenceManager
  }

  func getCurrentTwitterUser(in context: NSManagedObjectContext) -> Promise<TwitterUser> {
    guard isNotUITesting else { return Promise.value(TwitterUser.emptyInstance()) }
    return authorize()
      .then { self.networkManager.retrieveCurrentUser(with: $0.twitterUserId) }
      .get({ (twitterUser: TwitterUser) in
        context.performAndWait {
          let user = CKMUser.find(in: context)
          user?.avatar = twitterUser.profileImageData
          try? context.save()
        }
      })
  }

  /// default context is mainQueueContext
  func getCurrentTwitterUser() -> Promise<TwitterUser> {
    guard isNotUITesting else { return Promise.value(TwitterUser.emptyInstance()) }
    return getCurrentTwitterUser(in: persistenceManager.mainQueueContext())
  }

  func authorizedTwitterCredentials(presentingViewController controller: UIViewController) -> Promise<TwitterOAuthStorage> {
    guard isNotUITesting else { return Promise.value(TwitterOAuthStorage.emptyInstance()) }
    let handler = SafariURLHandler(viewController: controller, oauthSwift: networkManager.twitterOAuthManager)
    networkManager.twitterOAuthManager.authorizeURLHandler = handler
    return authorize()
  }

  func findTwitterUsers(using term: String, fromViewController controller: UIViewController) -> Promise<[TwitterUser]> {
    guard isNotUITesting else { return Promise.value([TwitterUser.emptyInstance()]) }
    let handler = SafariURLHandler(viewController: controller, oauthSwift: networkManager.twitterOAuthManager)
    networkManager.twitterOAuthManager.authorizeURLHandler = handler
    return authorize().then { _ in self.networkManager.findTwitterUsers(using: term) }
  }

  func defaultFollowingList(fromViewController controller: UIViewController) -> Promise<[TwitterUser]> {
    guard isNotUITesting else { return Promise.value([TwitterUser.emptyInstance()]) }
    let handler = SafariURLHandler(viewController: controller, oauthSwift: networkManager.twitterOAuthManager)
    networkManager.twitterOAuthManager.authorizeURLHandler = handler
    return authorize().then { _ in self.networkManager.defaultFollowingList() }
  }

  // MARK: private
  private func authorize() -> Promise<TwitterOAuthStorage> {
    if let credentials = persistenceManager.keychainManager.oauthCredentials() {
      let newCredential = OAuthSwiftCredential(consumerKey: twitterOAuth.consumerKey, consumerSecret: twitterOAuth.consumerSecret)
      newCredential.oauthToken = credentials.twitterOAuthToken
      newCredential.oauthTokenSecret = credentials.twitterOAuthTokenSecret
      networkManager.twitterOAuthManager.client = OAuthSwiftClient(credential: newCredential)
      return .value(credentials)
    } else {
      return networkManager.authorizeTwitterUser()
    }
  }
}
