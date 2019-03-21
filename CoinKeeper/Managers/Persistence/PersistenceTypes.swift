//
//  PersistenceTypes.swift
//  CoinKeeper
//
//  Created by Ben Winters on 5/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import CoreData
import PromiseKit
import PhoneNumberKit
import Strongbox

protocol PersistenceManagerType: DeviceCountryCodeProvider {
  var keychainManager: PersistenceKeychainType { get }
  var databaseManager: PersistenceDatabaseType { get }
  var userDefaultsManager: PersistenceUserDefaultsType { get }
  var contactCacheManager: ContactCacheManagerType { get }
  var hashingManager: HashingManager { get }

  func double(for key: CKUserDefaults.Key) -> Double
  func set(_ doubleValue: Double, for key: CKUserDefaults.Key)
  func integer(for key: CKUserDefaults.Key) -> Int
  func set(_ integerValue: Int, for key: CKUserDefaults.Key)
  func set(_ stringValue: CKUserDefaults.Value, for key: CKUserDefaults.Key)
  func set(_ string: String, for key: CKUserDefaults.Key)
  func string(for key: CKUserDefaults.Key) -> String?
  func set(_ array: [String], for key: CKUserDefaults.Key)
  func array(for key: CKUserDefaults.Key) -> [String]?
  func set(_ bool: Bool, for key: CKUserDefaults.Key)
  func set(_ date: Date, for key: CKUserDefaults.Key)
  func date(for key: CKUserDefaults.Key) -> Date?

  func bool(for key: CKUserDefaults.Key) -> Bool

  func resetPersistence()
  func resetWallet()
  func walletWords() -> [String]?

  func createBackgroundContext() -> NSManagedObjectContext
  func mainQueueContext() -> NSManagedObjectContext

  /// convenience function for calling `persistentStore(for:)` with default main context
  func persistentStore() -> NSPersistentStore?
  func persistentStore(for context: NSManagedObjectContext) -> NSPersistentStore?

  func deleteWallet(in context: NSManagedObjectContext)
  func persistUnacknowledgedInvitation(in context: NSManagedObjectContext, with btcPair: BitcoinUSDPair,
                                       contact: ContactType, fee: Int, acknowledgementId: String)
  func persistWalletId(from response: WalletResponse, in context: NSManagedObjectContext) -> Promise<Void>
  func persistUserId(from response: UserResponse, in context: NSManagedObjectContext) -> Promise<CKMUser>
  func persistVerificationStatus(from response: UserResponse, in context: NSManagedObjectContext) -> Promise<UserVerificationStatus>
  func persistAddedWalletAddresses(
    from responses: [WalletAddressResponse],
    metaAddresses: [CNBMetaAddress],
    in context: NSManagedObjectContext) -> Promise<Void>
  func persistTransactions(
    from transactionResponses: [TransactionResponse],
    in context: NSManagedObjectContext,
    relativeToCurrentHeight blockHeight: Int,
    fullSync: Bool
    ) -> Promise<Void>
  func persistTransactionSummaries(
    from responses: [AddressTransactionSummaryResponse],
    in context: NSManagedObjectContext
    ) -> Promise<Void>
  func persistTemporaryTransaction(
    from transactionData: CNBTransactionData,
    with outgoingTransactionData: OutgoingTransactionData,
    txid: String,
    invitation: CKMInvitation?,
    in context: NSManagedObjectContext
  )
  func persistReceivedSharedPayloads(
    _ payloads: [SharedPayloadV1],
    kit: PhoneNumberKit,
    in context: NSManagedObjectContext
  )
  func deleteTransactions(notIn txids: [String], in context: NSManagedObjectContext)
  func transactionsWithoutDayAveragePrice(in context: NSManagedObjectContext) -> Promise<[CKMTransaction]>
  func containsRegularTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple
  func containsDropbitTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple

  func walletId(in context: NSManagedObjectContext) -> String?
  func userId(in context: NSManagedObjectContext) -> String?
  func userVerificationStatus(in context: NSManagedObjectContext) -> UserVerificationStatus
  func userIsVerified(in context: NSManagedObjectContext) -> Bool
  func getAllInvitations(in context: NSManagedObjectContext) -> [CKMInvitation]
  func getUnacknowledgedInvitations(in context: NSManagedObjectContext) -> [CKMInvitation]

  /// Called when local userId is no longer valid on server
  func unverifyUser(in context: NSManagedObjectContext)

  func verifiedPhoneNumber() -> GlobalPhoneNumber?
  func deregisterPhone()

  /// Called when local walletId is no longer valid on server
  func removeWalletId(in context: NSManagedObjectContext)

  func serverPoolAddresses(in context: NSManagedObjectContext) -> [CKMServerAddress]
  func defaultHeaders(in context: NSManagedObjectContext) -> Promise<DefaultRequestHeaders>
  func acknowledgeInvitation(with outgoingTransactionData: OutgoingTransactionData,
                             response: WalletAddressRequestResponse,
                             in context: NSManagedObjectContext)

  func addressesProvidedForReceivedPendingDropBits(in context: NSManagedObjectContext) -> [String]

  func updateWalletLastIndexes(in context: NSManagedObjectContext)
  func lastReceiveAddressIndex(in context: NSManagedObjectContext) -> Int?
  func lastChangeAddressIndex(in context: NSManagedObjectContext) -> Int?

  func setLastLoginTime()
  func lastLoginTime() -> TimeInterval?

  /// Returns either the stored UUID or the one that has just been created and stored
  @discardableResult
  func findOrCreateDeviceId() -> UUID

  func deviceEndpointIds() -> DeviceEndpointIds?
  func deleteDeviceEndpointIds()

  func persist(pendingInvitationData data: PendingInvitationData)
  func pendingInvitations() -> [PendingInvitationData]
  func pendingInvitation(with id: String) -> PendingInvitationData?

  func backup(recoveryWords words: [String])
  func walletWordsBackedUp() -> Bool

  @discardableResult
  func removePendingInvitationData(with id: String) -> PendingInvitationData?

  func setDatabaseMigrationFlag(migrated: Bool, for version: DatabaseMigrationVersion)
  func databaseMigrationFlag(for version: DatabaseMigrationVersion) -> Bool
  func setKeychainMigrationFlag(migrated: Bool, for version: KeychainMigrationVersion)
  func keychainMigrationFlag(for version: KeychainMigrationVersion) -> Bool

  /// Look for any transactions sent to a phone number without a contact name, and provide a name if found, as a convenience when viewing tx history
  func matchContactsIfPossible()
}

extension PersistenceManagerType {
  func deviceCountryCode() -> Int? {
    return verifiedPhoneNumber()?.countryCode
  }
}

protocol PersistenceKeychainType: AnyObject {
  @discardableResult
  func store(anyValue value: Any?, key: CKKeychain.Key) -> Bool

  @discardableResult
  func store(valueToHash value: String?, key: CKKeychain.Key) -> Bool

  @discardableResult
  func store(deviceID: String) -> Bool

  @discardableResult
  func store(recoveryWords words: [String]) -> Bool

  @discardableResult
  func store(userPin pin: String) -> Bool

  func retrieveValue(for key: CKKeychain.Key) -> Any?
  func bool(for key: CKKeychain.Key) -> Bool?

  func backup(recoveryWords words: [String])
  func walletWordsBackedUp() -> Bool

  func deleteAll()
  func unverifyUser()

  init(store: KeychainAccessorType)
}

protocol PersistenceDatabaseType: AnyObject {

  var mainQueueContext: NSManagedObjectContext { get }

  func createBackgroundContext() -> NSManagedObjectContext

  func persistentStore(for context: NSManagedObjectContext) -> NSPersistentStore?

  func deleteAll(in context: NSManagedObjectContext)

  func persistTransactions(
    from transactionResponses: [TransactionResponse],
    in context: NSManagedObjectContext,
    relativeToCurrentHeight blockHeight: Int,
    fullSync: Bool
    ) -> Promise<Void>

  /// Returns set of unused receive address indices less than the max used index
  func persistTransactionSummaries(
    from responses: [AddressTransactionSummaryResponse],
    in context: NSManagedObjectContext
    ) -> Promise<Set<Int>>

  func persistTemporaryTransaction(
    from transactionData: CNBTransactionData,
    with outgoingTransactionData: OutgoingTransactionData,
    txid: String,
    invitation: CKMInvitation?,
    in context: NSManagedObjectContext
  )

  func persistReceivedSharedPayloads(
    _ payloads: [SharedPayloadV1],
    hasher: HashingManager,
    kit: PhoneNumberKit,
    contactCacheManager: ContactCacheManagerType,
    in context: NSManagedObjectContext
  )

  func deleteTransactions(notIn txids: [String], in context: NSManagedObjectContext)

  func transactionsWithoutDayAveragePrice(in context: NSManagedObjectContext) -> Promise<[CKMTransaction]>

  func persistWalletId(_ id: String, in context: NSManagedObjectContext) -> Promise<Void>
  func persistUserId(_ id: String, in context: NSManagedObjectContext) -> Promise<CKMUser>
  func persistVerificationStatus(_ status: String, in context: NSManagedObjectContext) -> Promise<UserVerificationStatus>
  func persistServerAddress(for metaAddress: CNBMetaAddress, createdAt: Date, wallet: CKMWallet, in context: NSManagedObjectContext) -> Promise<Void>
  func containsRegularTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple
  func containsDropbitTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple
  func getAllInvitations(in context: NSManagedObjectContext) -> [CKMInvitation]
  func getUnacknowledgedInvitations(in context: NSManagedObjectContext) -> [CKMInvitation]

  func walletId(in context: NSManagedObjectContext) -> String?
  func userId(in context: NSManagedObjectContext) -> String?
  func unverifyUser(in context: NSManagedObjectContext)
  func removeWalletId(in context: NSManagedObjectContext)

  func serverPoolAddresses(in context: NSManagedObjectContext) -> [CKMServerAddress]
  func addressesProvidedForReceivedPendingDropBits(in context: NSManagedObjectContext) -> [String]

  func userVerificationStatus(in context: NSManagedObjectContext) -> UserVerificationStatus

  func updateLastReceiveAddressIndex(index: Int, in context: NSManagedObjectContext)
  func updateLastChangeAddressIndex(index: Int, in context: NSManagedObjectContext)

  func lastReceiveIndex(in context: NSManagedObjectContext) -> Int?
  func lastChangeIndex(in context: NSManagedObjectContext) -> Int?

  func matchContactsIfPossible(with contactCacheManager: ContactCacheManagerType)
}

protocol PersistenceUserDefaultsType: AnyObject {

  static var standardDefaults: UserDefaults { get }
  func deleteAll()
  func deleteWallet()
  func unverifyUser()
  func removeWalletId()
  func deleteDeviceEndpointIds()
  func persist(pendingInvitationData data: PendingInvitationData)
  func pendingInvitations() -> [PendingInvitationData]
  func pendingInvitation(with id: String) -> PendingInvitationData?
  func removePendingInvitation(with id: String) -> PendingInvitationData?
  func setPendingInvitationFailed(_ invitation: PendingInvitationData)
  func deviceId() -> UUID?
  func setDeviceId(_ uuid: UUID)
  var receiveAddressIndexGaps: Set<Int> { get set }

}

extension PersistenceUserDefaultsType {

  static var standardDefaults: UserDefaults { return UserDefaults.standard }

}

/// KeychainAccessorType is a protocol to create an interface for a third-party library
protocol KeychainAccessorType {
  func archive(_ value: Any?, key: String) -> Bool
  func unarchive(objectForKey: String) -> Any?
}
extension Strongbox: KeychainAccessorType {
  func archive(_ value: Any?, key: String) -> Bool {
    return self.archive(value, key: key, accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
  }
}
