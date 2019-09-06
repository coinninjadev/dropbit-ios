//
//  PersistenceTypes.swift
//  DropBit
//
//  Created by Ben Winters on 5/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import CoreData
import PromiseKit
import Strongbox

protocol PersistenceManagerType: DeviceCountryCodeProvider {
  var keychainManager: PersistenceKeychainType { get }
  var databaseManager: PersistenceDatabaseType { get }
  var userDefaultsManager: PersistenceUserDefaultsType { get }
  var contactCacheManager: ContactCacheManagerType { get }
  var hashingManager: HashingManager { get }
  var brokers: PersistenceBrokersType { get }

  var viewContext: NSManagedObjectContext { get }
  func createBackgroundContext() -> NSManagedObjectContext

  /// convenience function for calling `persistentStore(for:)` with default main context
  func persistentStore() -> NSPersistentStore?
  func persistentStore(for context: NSManagedObjectContext) -> NSPersistentStore?

  func resetPersistence() throws

  func defaultHeaders(in context: NSManagedObjectContext) -> Promise<DefaultRequestHeaders>

  func persistTransactionSummaries(
    from responses: [AddressTransactionSummaryResponse],
    in context: NSManagedObjectContext)

  func persistReceivedSharedPayloads(
    _ payloads: [Data],
    in context: NSManagedObjectContext)

  /// Look for any transactions sent to a phone number without a contact name, and provide a name if found, as a convenience when viewing tx history
  func matchContactsIfPossible()

}

extension PersistenceManagerType {
  func deviceCountryCode() -> Int? {
    return brokers.user.verifiedPhoneNumber()?.countryCode
  }
}

protocol PersistenceKeychainType: AnyObject {

  /// Generally you should write to the keychain asynchronously using the other functions,
  /// which return a Promise so that the keychain is not accessed concurrently. Use this function judiciously.
  @discardableResult
  func storeSynchronously(anyValue value: Any?, key: CKKeychain.Key) -> Bool

  func store(anyValue value: Any?, key: CKKeychain.Key) -> Promise<Void>
  func store(valueToHash value: String?, key: CKKeychain.Key) -> Promise<Void>
  func store(deviceID: String) -> Promise<Void>
  func store(recoveryWords words: [String], isBackedUp: Bool) -> Promise<Void>
  func storeWalletWordsBackedUp(_ isBackedUp: Bool) -> Promise<Void>
  func store(userPin pin: String) -> Promise<Void>

  @discardableResult
  func store(oauthCredentials: TwitterOAuthStorage) -> Bool

  func retrieveValue(for key: CKKeychain.Key) -> Any?
  func bool(for key: CKKeychain.Key) -> Bool?

  func walletWordsBackedUp() -> Bool

  func oauthCredentials() -> TwitterOAuthStorage?

  func deleteAll()
  func unverifyUser(for identity: UserIdentityType)

  init(store: KeychainAccessorType)
}

protocol PersistenceDatabaseType: AnyObject {

  var sharedPayloadManager: SharedPayloadManagerType { get set }

  var viewContext: NSManagedObjectContext { get }

  func createBackgroundContext() -> NSManagedObjectContext

  func persistentStore(for context: NSManagedObjectContext) -> NSPersistentStore?

  func deleteAll(in context: NSManagedObjectContext)

  func persistTransactions(
    from transactionResponses: [TransactionResponse],
    in context: NSManagedObjectContext,
    relativeToCurrentHeight blockHeight: Int,
    fullSync: Bool
    ) -> Promise<Void>

  func persistTransactionSummaries(
    from responses: [AddressTransactionSummaryResponse],
    in context: NSManagedObjectContext)

  func persistTemporaryTransaction(
    from transactionData: CNBTransactionData,
    with outgoingTransactionData: OutgoingTransactionData,
    txid: String,
    invitation: CKMInvitation?,
    in context: NSManagedObjectContext
    ) -> CKMTransaction

  func deleteTransactions(notIn txids: [String], in context: NSManagedObjectContext)
  func latestTransaction(in context: NSManagedObjectContext) -> CKMTransaction?

  func transactionsWithoutDayAveragePrice(in context: NSManagedObjectContext) -> Promise<[CKMTransaction]>

  func persistWalletResponse(_ response: WalletResponse, in context: NSManagedObjectContext) throws
  func persistUserId(_ id: String, in context: NSManagedObjectContext)
  func persistVerificationStatus(_ status: String, in context: NSManagedObjectContext) -> Promise<UserVerificationStatus>
  func persistServerAddress(for metaAddress: CNBMetaAddress, createdAt: Date, wallet: CKMWallet, in context: NSManagedObjectContext) -> Promise<Void>
  func containsRegularTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple
  func containsDropbitTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple
  func getAllInvitations(in context: NSManagedObjectContext) -> [CKMInvitation]
  func getUnacknowledgedInvitations(in context: NSManagedObjectContext) -> [CKMInvitation]

  func walletId(in context: NSManagedObjectContext) -> String?
  func walletFlags(in context: NSManagedObjectContext) -> Int
  func userId(in context: NSManagedObjectContext) -> String?
  func unverifyUser(in context: NSManagedObjectContext)
  func removeWalletId(in context: NSManagedObjectContext)

  func serverPoolAddresses(in context: NSManagedObjectContext) -> [CKMServerAddress]
  func addressesProvidedForReceivedPendingDropBits(in context: NSManagedObjectContext) -> [String]

  func userVerificationStatus(in context: NSManagedObjectContext) -> UserVerificationStatus

  func updateLastReceiveAddressIndex(index: Int?, in context: NSManagedObjectContext)
  func updateLastChangeAddressIndex(index: Int?, in context: NSManagedObjectContext)

  func lastReceiveIndex(in context: NSManagedObjectContext) -> Int?
  func lastChangeIndex(in context: NSManagedObjectContext) -> Int?

  func matchContactsIfPossible(with contactCacheManager: ContactCacheManagerType)
}

protocol PersistenceUserDefaultsType: AnyObject {

  /// Avoid using the methods of UserDefaults directly,
  /// use the extension functions with CKUserDefaults.Key instead.
  var standardDefaults: UserDefaults { get }

  func deleteAll()
  func deleteWallet()
  func unverifyUser()

}

extension PersistenceUserDefaultsType {

  func double(for key: CKUserDefaults.Key) -> Double {
    return standardDefaults.double(forKey: key.defaultsString)
  }

  func set(_ doubleValue: Double, for key: CKUserDefaults.Key) {
    standardDefaults.set(doubleValue, forKey: key.defaultsString)
  }

  func integer(for key: CKUserDefaults.Key) -> Int {
    return standardDefaults.integer(forKey: key.defaultsString)
  }

  func set(_ integerValue: Int, for key: CKUserDefaults.Key) {
    standardDefaults.set(integerValue, forKey: key.defaultsString)
  }

  func string(for key: CKUserDefaults.Key) -> String? {
    return standardDefaults.string(forKey: key.defaultsString)
  }

  func array(for key: CKUserDefaults.Key) -> [Any]? {
    return standardDefaults.array(forKey: key.defaultsString)
  }

  func set(_ array: [String], for key: CKUserDefaults.Key) {
    standardDefaults.set(array, forKey: key.defaultsString)
  }

  func set(_ string: String, for key: CKUserDefaults.Key) {
    standardDefaults.set(string, forKey: key.defaultsString)
  }

  func set(_ stringValue: CKUserDefaults.Value, for key: CKUserDefaults.Key) {
    set(stringValue.defaultsString, for: key)
  }

  func set(stringValue: String, for key: CKUserDefaults.Key) {
    standardDefaults.set(stringValue, forKey: key.defaultsString)
  }

  func set(_ bool: Bool, for key: CKUserDefaults.Key) {
    standardDefaults.set(bool, forKey: key.defaultsString)
  }

  func bool(for key: CKUserDefaults.Key) -> Bool {
    return standardDefaults.bool(forKey: key.defaultsString)
  }

  func set(_ date: Date, for key: CKUserDefaults.Key) {
    standardDefaults.set(date, forKey: key.defaultsString)
  }

  func date(for key: CKUserDefaults.Key) -> Date? {
    return standardDefaults.object(forKey: key.defaultsString) as? Date
  }

  func object(for key: CKUserDefaults.Key) -> Any? {
    return standardDefaults.object(forKey: key.defaultsString)
  }

  func set(_ object: Any?, for key: CKUserDefaults.Key) {
    standardDefaults.set(object, forKey: key.defaultsString)
  }

  func value(for key: CKUserDefaults.Key) -> Any? {
    return standardDefaults.value(forKey: key.defaultsString)
  }

  func setValue(_ value: Any?, for key: CKUserDefaults.Key) {
    standardDefaults.setValue(value, forKey: key.defaultsString)
  }

  func removeValue(for key: CKUserDefaults.Key) {
    standardDefaults.set(nil, forKey: key.defaultsString)
  }

  func removeValues(forKeys keys: [CKUserDefaults.Key]) {
    keys.forEach { removeValue(for: $0) }
  }

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
