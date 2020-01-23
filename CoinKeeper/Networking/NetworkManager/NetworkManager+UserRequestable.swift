//
//  NetworkManager+UserRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit

protocol UserRequestable: AnyObject {

  func createUser(walletId: String, body: UserIdentityBody) -> Promise<UserResponse>
  func verifyUser(id: String, body: VerifyUserBody) -> Promise<UserResponse>
  func addIdentity(body: UserIdentityBody) -> Promise<UserIdentityResponse>
  func deleteIdentity(identity: String) -> Promise<Void>
  func getUser() -> Promise<UserResponse>
  func queryUsers(identityHashes: [String]) -> Promise<StringDictResponse>
  func updateUserPublicURL(isPrivate: Bool) -> Promise<UserResponse>
  func patchHolidayType(holidayType: HolidayType) -> Promise<UserResponse>

  /**
   This is typically used when the entered verification code is incorrect or expired.
   This may also be used in case of 200 response on createUser() to continue verification with an already registered user.
   */
  func resendVerification(headers: DefaultRequestHeaders, body: UserIdentityBody) -> Promise<UserResponse>

}

/**
 The headers provided in this dictionary should not include the signature
 or timestamp as those are added automatically through the AuthPlugin.
 */
public protocol CKRequestHeadersProvider {
  var dictionary: Headers { get }
}

public struct CreateUserHeaders: CKRequestHeadersProvider {
  var walletId: String

  public var dictionary: Headers {
    return CNHeaderParameter.dictionary(withKeyValues: [.authWalletId: walletId])
  }
}

extension NetworkManager: UserRequestable {

  func createUser(walletId: String, body: UserIdentityBody) -> Promise<UserResponse> {
    let headers = CreateUserHeaders(walletId: walletId)
    return cnProvider.request(UserTarget.create(headers, body))
      .recover { error -> Promise<UserResponse> in

        if let networkError = error as? DBTError.Network {
          switch networkError {
          case .recordAlreadyExists(let response):
            let userResponse = try response.map(UserResponse.self, using: UserResponse.decoder)
            throw DBTError.UserRequest.userAlreadyExists(userResponse.id, body)
          case .twilioError(let response):
            let userResponse = try response.map(UserResponse.self, using: UserResponse.decoder)
            throw DBTError.UserRequest.twilioError(userResponse, body)
          default:
            throw error
          }
        } else {
          throw error
        }
    }
  }

  func patchHolidayType(holidayType: HolidayType) -> Promise<UserResponse> {
    return cnProvider.request(UserTarget.patchProfile(holidayType))
  }

  func verifyUser(id: String, body: VerifyUserBody) -> Promise<UserResponse> {
    return cnProvider.request(UserTarget.verify(id, body))
  }

  func addIdentity(body: UserIdentityBody) -> Promise<UserIdentityResponse> {
    return cnProvider.request(UserIdentityTarget.add(body))
  }

  func getUser() -> Promise<UserResponse> {
    return cnProvider.request(UserTarget.get)
  }

  func queryUsers(identityHashes: [String]) -> Promise<StringDictResponse> {
    return cnProvider.requestObject(UserQueryTarget.query(identityHashes))
      .then { (jsonObject: JSONObject) -> Promise<StringDictResponse> in
        guard let stringDict = jsonObject as? [String: String] else {
          throw DBTError.Network.badResponse
        }

        return Promise.value(stringDict)
    }
  }

  /// pass in the headers as a combined struct so that the struct can be used as the value of the preceding promise
  func resendVerification(headers: DefaultRequestHeaders, body: UserIdentityBody) -> Promise<UserResponse> {
    return cnProvider.request(UserTarget.resendVerification(headers, body))
      .recover { error -> Promise<UserResponse> in
        if let networkError = error as? DBTError.Network, case let .twilioError(response) = networkError {
          let userResponse = try response.map(UserResponse.self, using: UserResponse.decoder)
          throw DBTError.UserRequest.twilioError(userResponse, body)
        } else {
          throw error
        }
    }
  }

  func deleteIdentity(identity: String) -> Promise<Void> {
    return cnProvider.requestVoid(UserTarget.deleteIdentity(identity))
  }

  func updateUserPublicURL(isPrivate: Bool) -> Promise<UserResponse> {
    return cnProvider.request(UserTarget.updateIsPrivate(isPrivate))
  }
}
