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

  func createUser(walletId: String, body: UserIdentityBody) -> Promise<UserResponse> {
    return Promise { _ in }
  }

  func verifyUser(body: VerifyUserBody) -> Promise<UserResponse> {
    return Promise { _ in }
  }

  func verifyUser(body: VerifyUserBody, credentials: TwitterOAuthStorage?) -> Promise<UserResponse> {
    return Promise { _ in }
  }

  func addIdentity(body: UserIdentityBody) -> Promise<UserIdentityResponse> {
    return Promise { _ in }
  }

  func deleteIdentity(identity: String) -> Promise<Void> {
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

  func resendVerification(headers: DefaultRequestHeaders, body: UserIdentityBody) -> Promise<UserResponse> {
    return Promise { _ in }
  }

  func updateUserPublicURL(isPrivate: Bool) -> Promise<UserResponse> {
    return Promise { _ in }
  }
}
