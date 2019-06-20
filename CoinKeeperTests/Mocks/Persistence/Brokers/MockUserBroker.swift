//
//  MockUserBroker.swift
//  DropBitUITests
//
//  Created by Ben Winters on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import Foundation
import PromiseKit
@testable import DropBit

class MockUserBroker: CKPersistenceBroker, UserBrokerType {
  func persistUserId(_ userId: String, in context: NSManagedObjectContext) { }
  func persistUserPublicURLInfo(from response: UserResponse, in context: NSManagedObjectContext) { }

  func getUserPublicURLInfo(in context: NSManagedObjectContext) -> UserPublicURLInfo? {
    return nil
  }

  func persistVerificationStatus(from response: UserResponse, in context: NSManagedObjectContext) -> Promise<UserVerificationStatus> {
    return Promise { _ in }
  }

  var unverifyUserWasCalled = false
  func unverifyUser(in context: NSManagedObjectContext) {
    unverifyUserWasCalled = true
  }

  func unverifyAllIdentities() { }

  func verifiedPhoneNumber() -> GlobalPhoneNumber? {
    return nil
  }

  var userIdValue: String?
  func userId(in context: NSManagedObjectContext) -> String? {
    return userIdValue
  }

  func verifiedIdentities(in context: NSManagedObjectContext) -> [UserIdentityType] {
    return []
  }

  func userIsVerified(in context: NSManagedObjectContext) -> Bool {
    return false
  }

  var userIsVerifiedValue = true
  func userIsVerified(using type: UserIdentityType, in context: NSManagedObjectContext) -> Bool {
    return userIsVerifiedValue
  }

  var userVerificationStatusValue: UserVerificationStatus = .unverified
  func userVerificationStatus(in context: NSManagedObjectContext) -> UserVerificationStatus {
    return userVerificationStatusValue
  }

  func serverPoolAddresses(in context: NSManagedObjectContext) -> [CKMServerAddress] {
    return []
  }

}
