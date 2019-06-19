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

  func unverifyUser(in context: NSManagedObjectContext) { }
  func unverifyAllIdentities() { }

  func verifiedPhoneNumber() -> GlobalPhoneNumber? {
    return nil
  }

  func userId(in context: NSManagedObjectContext) -> String? {
    return nil
  }

  func verifiedIdentities(in context: NSManagedObjectContext) -> [UserIdentityType] {
    return []
  }

  func userIsVerified(in context: NSManagedObjectContext) -> Bool {
    return false
  }

  func userIsVerified(using type: UserIdentityType, in context: NSManagedObjectContext) -> Bool {
    return false
  }

  func userVerificationStatus(in context: NSManagedObjectContext) -> UserVerificationStatus {
    return .pending
  }

  func serverPoolAddresses(in context: NSManagedObjectContext) -> [CKMServerAddress] {
    return []
  }

}
