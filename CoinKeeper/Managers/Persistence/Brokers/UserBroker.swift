//
//  UserBroker.swift
//  DropBit
//
//  Created by Ben Winters on 6/17/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import PhoneNumberKit
import PromiseKit

class UserBroker: CKPersistenceBroker, UserBrokerType {

  /// Will only persist a non-empty string to protect when that is returned by the server for some routes
  func persistUserId(_ userId: String, in context: NSManagedObjectContext) {
    guard userId.isNotEmpty else { return }

    userDefaultsManager.set(stringValue: userId, for: .userID)
    databaseManager.persistUserId(userId, in: context)
  }

  func persistUserPublicURLInfo(from response: UserResponse, in context: NSManagedObjectContext) {
    let user = CKMUser.find(in: context)
    user?.publicURLIsPrivate = response.private ?? false
  }

  func getUserPublicURLInfo(in context: NSManagedObjectContext) -> UserPublicURLInfo? {
    guard let user = CKMUser.find(in: context) else { return nil }
    let phoneIdentity = self.phoneIdentity(for: user, in: context)
    let twitterIdentity = self.twitterIdentity()
    let identities = [phoneIdentity, twitterIdentity].compactMap { $0 }

    return UserPublicURLInfo(private: user.publicURLIsPrivate, identities: identities)
  }

  private func twitterIdentity() -> PublicURLIdentity? {
    guard let creds = keychainManager.oauthCredentials() else { return nil }
    return PublicURLIdentity(twitterCredentials: creds)
  }

  private func phoneIdentity(for user: CKMUser, in context: NSManagedObjectContext) -> PublicURLIdentity? {
    let hasher = HashingManager()
    guard let salt = try? hasher.salt(),
      let phoneNumber = self.verifiedPhoneNumber() else { return nil }

    let hash = hasher.hash(phoneNumber: phoneNumber, salt: salt, parsedNumber: nil)
    let phoneIdentity = PublicURLIdentity(fullPhoneHash: hash)
    return phoneIdentity
  }

  func persistVerificationStatus(from response: UserResponse, in context: NSManagedObjectContext) -> Promise<UserVerificationStatus> {
    return databaseManager.persistVerificationStatus(response.status, in: context)
  }

  /// Call this to reset the user state to match the state of tapping Skip on verification
  func unverifyUser(in context: NSManagedObjectContext) {
    // Perform on both contexts to ensure that willSave/didSave observers receive notification on main queue for badge updates
    databaseManager.unverifyUser(in: context)
    databaseManager.unverifyUser(in: databaseManager.viewContext)

    userDefaultsManager.removeValues(forKeys: [.userID])
    keychainManager.unverifyUser(for: .phone)
    keychainManager.unverifyUser(for: .twitter)
  }

  func userIsVerified(in context: NSManagedObjectContext) -> Bool {
    return userVerificationStatus(in: context) == .verified
  }

  func verifiedIdentities(in context: NSManagedObjectContext) -> [UserIdentityType] {
    guard userIsVerified(in: context) else { return [] }
    var retVal: [UserIdentityType] = []
    if keychainManager.oauthCredentials() != nil {
      retVal.append(.twitter)
    }
    if verifiedPhoneNumber() != nil {
      retVal.append(.phone)
    }
    return retVal
  }

  func userIsVerified(using type: UserIdentityType, in context: NSManagedObjectContext) -> Bool {
    let verifiedTypes = verifiedIdentities(in: context)
    return verifiedTypes.contains(type)
  }

  func userVerificationStatus(in context: NSManagedObjectContext) -> UserVerificationStatus {
    return databaseManager.userVerificationStatus(in: context)
  }

  func serverPoolAddresses(in context: NSManagedObjectContext) -> [CKMServerAddress] {
    return databaseManager.serverPoolAddresses(in: context)
  }

  /// Should be called when last identity is deverified
  func unverifyAllIdentities() {
    let context = databaseManager.viewContext
    databaseManager.unverifyUser(in: context)
    keychainManager.unverifyUser(for: .phone)
    keychainManager.unverifyUser(for: .twitter)
    userDefaultsManager.unverifyUser()
  }

  func verifiedPhoneNumber() -> GlobalPhoneNumber? {
    guard let nationalNumber = keychainManager.retrieveValue(for: .phoneNumber) as? String else { return nil }
    let countryCode = keychainManager.retrieveValue(for: .countryCode) as? Int ?? 1 //default to 1 for legacy users
    return GlobalPhoneNumber(countryCode: countryCode, nationalNumber: nationalNumber)
  }

  func userId(in context: NSManagedObjectContext) -> String? {
    if let userID = userDefaultsManager.string(for: .userID) {
      return userID
    } else {
      guard let userID = databaseManager.userId(in: context) else { return nil }
      userDefaultsManager.set(stringValue: userID, for: .userID)
      return userID
    }
  }

}
