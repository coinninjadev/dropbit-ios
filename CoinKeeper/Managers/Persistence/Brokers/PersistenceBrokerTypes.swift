//
//  PersistenceBrokerTypes.swift
//  DropBit
//
//  Created by Ben Winters on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import CoreData
import Foundation
import PromiseKit

protocol PersistenceBrokersType: AnyObject {

  var activity: ActivityBrokerType { get }
  var checkIn: CheckInBrokerType { get }
  var device: DeviceBrokerType { get }
  var invitation: InvitationBrokerType { get }
  var migration: MigrationBrokerType { get }
  var preferences: PreferencesBrokerType { get }
  var transaction: TransactionBrokerType { get }
  var user: UserBrokerType { get }
  var wallet: WalletBrokerType { get }

}

protocol ActivityBrokerType: AnyObject {

  /// Initial value will return false, so getter and setter reverse value
  var isFirstTimeOpeningApp: Bool { get set }

  func setLastLoginTime()

  var lastLoginTime: TimeInterval? { get }
  var lastSuccessfulSync: Date? { get set }
  var lastPublishedMessageTime: TimeInterval? { get set }
  var shownMessageIds: [String] { get set }
  var unseenTransactionChangesExist: Bool { get set }
  var lastContactCacheReload: Date? { get set }
  var backupWordsReminderShown: Bool { get set }

}

protocol CheckInBrokerType: AnyObject {

  var cachedBTCUSDRate: Double { get set }
  var cachedBlockHeight: Int { get set }
  var cachedBestFee: Double { get set }
  var cachedBetterFee: Double { get set }
  var cachedGoodFee: Double { get set }

}

protocol DeviceBrokerType: AnyObject {

  /// Returns either the stored UUID or the one that has just been created and stored
  @discardableResult
  func findOrCreateDeviceId() -> UUID

  func deviceEndpointIds() -> DeviceEndpointIds?
  func deleteDeviceEndpointIds()
  func setDeviceToken(string: String)

  var serverDeviceId: String? { get set }
  var deviceEndpointId: String? { get set }
  var pushToken: String? { get set }

}

protocol InvitationBrokerType: AnyObject {

  func getUnacknowledgedInvitations(in context: NSManagedObjectContext) -> [CKMInvitation]
  func getAllInvitations(in context: NSManagedObjectContext) -> [CKMInvitation]
  func persistUnacknowledgedInvitation(withDTO outgoingDTO: OutgoingInvitationDTO,
                                       acknowledgementId: String,
                                       in context: NSManagedObjectContext)
  func addressesProvidedForReceivedPendingDropBits(in context: NSManagedObjectContext) -> [String]
  func acknowledgeInvitation(with outgoingTransactionData: OutgoingTransactionData,
                             response: WalletAddressRequestResponse,
                             in context: NSManagedObjectContext)

}

protocol MigrationBrokerType: AnyObject {

  func setDatabaseMigrationFlag(migrated: Bool, for version: DatabaseMigrationVersion)
  func databaseMigrationFlag(for version: DatabaseMigrationVersion) -> Bool
  func setKeychainMigrationFlag(migrated: Bool, for version: KeychainMigrationVersion)
  func keychainMigrationFlag(for version: KeychainMigrationVersion) -> Bool
  func contactCacheMigrationFlag(for version: ContactCacheMigrationVersion) -> Bool
  func setContactCacheMigrationFlag(migrated: Bool, for version: ContactCacheMigrationVersion)

}

protocol PreferencesBrokerType: AnyObject {

  var dustProtectionMinimumAmount: Int { get }
  var dustProtectionIsEnabled: Bool { get set }
  var yearlyPriceHighNotificationIsEnabled: Bool { get set }
  var selectedCurrency: SelectedCurrency { get set }
  var dontShowShareTransaction: Bool { get set }
  var didOptOutOfInvitationPopup: Bool { get set }
  var adjustableFeesIsEnabled: Bool { get set }
  var preferredTransactionFeeType: TransactionFeeType { get set }
  var dontShowLightningRefill: Bool { get set }

}

protocol TransactionBrokerType: AnyObject {

  func persistTransactions(
    from transactionResponses: [TransactionResponse],
    in context: NSManagedObjectContext,
    relativeToCurrentHeight blockHeight: Int,
    fullSync: Bool
    ) -> Promise<Void>

  @discardableResult
  func persistTemporaryTransaction(
    from transactionData: CNBTransactionData,
    with outgoingTransactionData: OutgoingTransactionData,
    txid: String,
    invitation: CKMInvitation?,
    in context: NSManagedObjectContext
    ) -> CKMTransaction

  func containsRegularTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple
  func containsDropbitTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple
  func deleteTransactions(notIn txids: [String], in context: NSManagedObjectContext)
  func transactionsWithoutDayAveragePrice(in context: NSManagedObjectContext) -> Promise<[CKMTransaction]>

}

protocol UserBrokerType: AnyObject {

  /// Will only persist a non-empty string to protect when that is returned by the server for some routes
  func persistUserId(_ userId: String, in context: NSManagedObjectContext)

  func persistUserPublicURLInfo(from response: UserResponse, in context: NSManagedObjectContext)
  func getUserPublicURLInfo(in context: NSManagedObjectContext) -> UserPublicURLInfo?
  func persistVerificationStatus(from response: UserResponse, in context: NSManagedObjectContext) -> Promise<UserVerificationStatus>

  /// Call this to reset the user state to match the state of tapping Skip on verification
  func unverifyUser(in context: NSManagedObjectContext)

  /// Should be called when last identity is deverified
  func unverifyAllIdentities()

  func verifiedPhoneNumber() -> GlobalPhoneNumber?
  func userId(in context: NSManagedObjectContext) -> String?
  func verifiedIdentities(in context: NSManagedObjectContext) -> [UserIdentityType]
  func userIsVerified(in context: NSManagedObjectContext) -> Bool
  func userIsVerified(using type: UserIdentityType, in context: NSManagedObjectContext) -> Bool
  func userVerificationStatus(in context: NSManagedObjectContext) -> UserVerificationStatus
  func serverPoolAddresses(in context: NSManagedObjectContext) -> [CKMServerAddress]

}

protocol WalletBrokerType: AnyObject {

  func walletId(in context: NSManagedObjectContext) -> String?
  func resetWallet() throws
  func walletWords() -> [String]?
  func persistWalletId(from response: WalletResponse, in context: NSManagedObjectContext) throws
  func removeWalletId(in context: NSManagedObjectContext)
  func deleteWallet(in context: NSManagedObjectContext)
  func walletWordsBackedUp() -> Bool

  /// The responses should correspond 1-to-1 with the metaAddresses, order is irrelevant.
  func persistAddedWalletAddresses(
    from responses: [WalletAddressResponse],
    metaAddresses: [CNBMetaAddress],
    in context: NSManagedObjectContext) -> Promise<Void>

  func updateWalletLastIndexes(in context: NSManagedObjectContext)
  func lastReceiveAddressIndex(in context: NSManagedObjectContext) -> Int?
  func lastChangeAddressIndex(in context: NSManagedObjectContext) -> Int?
  var receiveAddressIndexGaps: Set<Int> { get set }

}
