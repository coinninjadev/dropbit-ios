//
//  NetworkManager+UserRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit

protocol UserRequestable: AnyObject {

  func createUser(walletId: String, body: CreateUserBody) -> Promise<UserResponse>
  func verifyUser(phoneNumber: GlobalPhoneNumber, code: String) -> Promise<UserResponse>
  func verifyUser(twitterCredentials: TwitterOAuthStorage) -> Promise<UserResponse>
  func getUser() -> Promise<UserResponse>
  func queryUsers(phoneNumberHashes: [String]) -> Promise<StringDictResponse>

  /**
   This is typically used when the entered verification code is incorrect or expired.
   This may also be used in case of 200 response on createUser() to continue verification with an already registered user.
   */
  func resendVerification(headers: DefaultRequestHeaders, body: CreateUserBody) -> Promise<UserResponse>

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

  func createUser(walletId: String, body: CreateUserBody) -> Promise<UserResponse> {
    let headers = CreateUserHeaders(walletId: walletId)
    return cnProvider.request(UserTarget.create(headers, body))
      .recover { error -> Promise<UserResponse> in

        if let networkError = error as? CKNetworkError {
          switch networkError {
          case .recordAlreadyExists(let response):
            let userResponse = try response.map(UserResponse.self, using: UserResponse.decoder)
            throw UserProviderError.userAlreadyExists(userResponse.id, body)
          case .twilioError(let response):
            let userResponse = try response.map(UserResponse.self, using: UserResponse.decoder)
            throw UserProviderError.twilioError(userResponse, body)
          default:
            throw error
          }
        } else {
          throw error
        }
    }
  }

  func verifyUser(phoneNumber: GlobalPhoneNumber, code: String) -> Promise<UserResponse> {
    let body = VerifyUserBody(phoneNumber: phoneNumber, code: code)
    return cnProvider.request(UserTarget.verify(body))
  }

  func verifyUser(twitterCredentials: TwitterOAuthStorage) -> Promise<UserResponse> {
    let body = VerifyUserBody(twitterCredentials: twitterCredentials)
    return cnProvider.request(UserTarget.verify(body))
  }

  func getUser() -> Promise<UserResponse> {
    return cnProvider.request(UserTarget.get)
  }

  func queryUsers(phoneNumberHashes: [String]) -> Promise<StringDictResponse> {
    return cnProvider.requestObject(UserQueryTarget.query(phoneNumberHashes))
      .then { (jsonObject: JSONObject) -> Promise<StringDictResponse> in
        guard let stringDict = jsonObject as? [String: String] else {
          throw CKNetworkError.badResponse
        }

        return Promise.value(stringDict)
    }
  }

  /// pass in the headers as a combined struct so that the struct can be used as the value of the preceding promise
  func resendVerification(headers: DefaultRequestHeaders, body: CreateUserBody) -> Promise<UserResponse> {
    return cnProvider.request(UserTarget.resendVerification(headers, body))
      .recover { error -> Promise<UserResponse> in
        if let networkError = error as? CKNetworkError, case let .twilioError(response) = networkError {
          let userResponse = try response.map(UserResponse.self, using: UserResponse.decoder)
          throw UserProviderError.twilioError(userResponse, body)
        } else {
          throw error
        }
    }
  }

}
