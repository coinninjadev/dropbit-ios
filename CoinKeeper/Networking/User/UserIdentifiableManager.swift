//
//  UserIdentifiableManager.swift
//  DropBit
//
//  Created by Mitchell Malleo on 12/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit
import Moya
import CoreData

protocol UserIdentifiableManagerType {
  var networkManager: NetworkManagerType { get }
  var persistenceManager: PersistenceManagerType { get }
  var delegate: TwilioErrorDelegate? { get set }

  func registerUser(with body: UserIdentityBody,
                    in context: NSManagedObjectContext) -> Promise<UserIdentifiable>
  func checkAndPersistVerificationStatus(from response: UserResponse,
                                         in context: NSManagedObjectContext) -> Promise<Void>
}

class UserIdentifiableManager: UserIdentifiableManagerType {

  var networkManager: NetworkManagerType
  var persistenceManager: PersistenceManagerType

  weak var delegate: TwilioErrorDelegate?

  init(networkManager: NetworkManagerType,
       persistenceManager: PersistenceManagerType) {
    self.networkManager = networkManager
    self.persistenceManager = persistenceManager
  }

  func registerUser(with body: UserIdentityBody,
                    in context: NSManagedObjectContext) -> Promise<UserIdentifiable> {
    var maybeWalletId: String?
    context.performAndWait {
      maybeWalletId = self.persistenceManager.brokers.wallet.walletId(in: context)
    }
    guard let walletId = maybeWalletId else {
      return Promise { $0.reject(DBTError.Persistence.missingValue(key: "wallet ID")) }
    }

    return self.createUserOrIdentity(walletId: walletId, body: body, in: context)
      .recover { (error: Error) -> Promise<UserIdentifiable> in
        return self.handleCreateUserError(error, walletId: walletId, in: context)
          .map { $0 as UserIdentifiable }
    }
  }

  private func createUserOrIdentity(
    walletId: String,
    body: UserIdentityBody,
    in context: NSManagedObjectContext
    ) -> Promise<UserIdentifiable> {
    let verifiedIdentities = self.persistenceManager.brokers.user.verifiedIdentities(in: context)
    if verifiedIdentities.isEmpty {
      return self.networkManager.createUser(walletId: walletId, body: body).map { $0 as UserIdentifiable }
    } else {
      guard let userId = self.persistenceManager.brokers.user.userId(in: context) else {
        return Promise(error: DBTError.Persistence.noUser)
      }
      return self.networkManager.addIdentity(body: body)
        .map { _ in UserIdWrapper(id: userId) as UserIdentifiable }
    }
  }

  func checkAndPersistVerificationStatus(from response: UserResponse,
                                         in context: NSManagedObjectContext) -> Promise<Void> {
    guard let statusCase = UserVerificationStatus(rawValue: response.status) else {
      return Promise { $0.reject(DBTError.Network.responseMissingValue(keyPath: UserResponseKey.status.path)) }
    }
    guard statusCase == .verified else {
      return Promise { $0.reject(DBTError.UserRequest.unexpectedStatus(statusCase)) }
    }

    return persistenceManager.brokers.user.persistVerificationStatus(from: response, in: context).asVoid()
  }

  /// If createUser results in statusCode 200, that function rejects with .userAlreadyExists and
  /// we recover by calling resendVerification(). In the case of a Twilio error, we notify the delegate
  /// for analytics and continue as normal. In both cases we eventually return a UserResponse so that
  /// we can persist the userId returned by the server.
  private func handleCreateUserError(_ error: Error,
                                     walletId: String,
                                     in context: NSManagedObjectContext) -> Promise<UserIdentifiable> {
    if let providerError = error as? DBTError.UserRequest {
      switch providerError {
      case .userAlreadyExists(let userId, let body):
        //ignore walletId available in the error in case it is different from the walletId we provided
        let resendHeaders = DefaultRequestHeaders(walletId: walletId, userId: userId)

        return self.networkManager.resendVerification(headers: resendHeaders, body: body)
          .map { _ in UserIdWrapper(id: userId) as UserIdentifiable } // pass along the known userId, the /resend response does not include it
          .recover { (error: Error) -> Promise<UserIdentifiable> in
            if let providerError = error as? DBTError.UserRequest,
              case let .twilioError(userResponse, _) = providerError {
              self.delegate?.didReceiveTwilioError(for: body.identity, route: .resendVerification)
              return Promise.value(userResponse)
            } else {
              throw error
            }
        }
      case .twilioError(let userResponse, let body):
        self.delegate?.didReceiveTwilioError(for: body.identity, route: .createUser)
        return Promise.value(userResponse)
      default:
        return Promise(error: error)
      }
    } else {
      return Promise(error: error)
    }
  }
}
