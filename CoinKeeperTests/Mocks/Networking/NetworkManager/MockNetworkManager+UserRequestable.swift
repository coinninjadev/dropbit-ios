//
//  MockNetworkManager+UserRequestable.swift
//  DropBitTests
//
//  Created by Ben Winters on 10/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import PromiseKit

extension MockNetworkManager: UserRequestable {

  func createUser(walletId: String, body: CreateUserBody) -> Promise<UserResponse> {
    return Promise { _ in }
  }

  func verifyUser(phoneNumber: GlobalPhoneNumber, code: String) -> Promise<UserResponse> {
    return Promise { _ in }
  }

  func verifyUser(twitterCredentials: TwitterOAuthStorage) -> Promise<UserResponse> {
    return Promise { _ in }
  }

  func getUser() -> Promise<UserResponse> {
    getUserWasCalled = true
    let error = getUserError ?? CKNetworkError.emptyResponse
    // reject so that intermediate promises don't need to be filled in and the catch block
    // will call the completion handler with the test's assertions
    return Promise { $0.reject(error) }
  }

  func queryUsers(phoneNumberHashes: [String]) -> Promise<StringDictResponse> {
    return Promise { _ in }
  }

  func resendVerification(headers: DefaultRequestHeaders, body: CreateUserBody) -> Promise<UserResponse> {
    return Promise { _ in }
  }

}
