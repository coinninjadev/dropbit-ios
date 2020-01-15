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
  func patchHolidayType(holidayType: HolidayType) -> Promise<UserResponse> {
    return Promise { _ in }
  }

  func createUser(walletId: String, body: UserIdentityBody) -> Promise<UserResponse> {
    return Promise { _ in }
  }

  func verifyUser(id: String, body: VerifyUserBody) -> Promise<UserResponse> {
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
    let error = getUserError ?? DBTError.Network.emptyResponse
    // reject so that intermediate promises don't need to be filled in and the catch block
    // will call the completion handler with the test's assertions
    return Promise { $0.reject(error) }
  }

  func queryUsers(identityHashes: [String]) -> Promise<StringDictResponse> {
    return Promise { _ in }
  }

  func resendVerification(headers: DefaultRequestHeaders, body: UserIdentityBody) -> Promise<UserResponse> {
    return Promise { _ in }
  }

  func updateUserPublicURL(isPrivate: Bool) -> Promise<UserResponse> {
    return Promise { _ in }
  }
}
