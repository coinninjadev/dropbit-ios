//
// Created by BJ Miller on 2/14/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import CoreData
import PhoneNumberKit
import PromiseKit
@testable import DropBit

class MockPersistenceManager: PersistenceManagerType {

  var keychainManager: PersistenceKeychainType
  var databaseManager: PersistenceDatabaseType
  var userDefaultsManager: PersistenceUserDefaultsType
  var contactCacheManager: ContactCacheManagerType
  var hashingManager: HashingManager = HashingManager()

  init(keychainManager: PersistenceKeychainType = MockPersistenceKeychainManager(store: MockKeychainAccessorType()),
       databaseManager: PersistenceDatabaseType = MockPersistenceDatabaseManager(),
       userDefaultsManager: PersistenceUserDefaultsType = MockUserDefaultsManager(),
       contactCacheManager: ContactCacheManagerType = MockContactCacheManager()
    ) {
    self.keychainManager = keychainManager
    self.databaseManager = databaseManager
    self.userDefaultsManager = userDefaultsManager
    self.contactCacheManager = contactCacheManager
  }

  func set(_ array: [String], for key: CKUserDefaults.Key) {}
  func set(_ string: String, for key: CKUserDefaults.Key) {}
  func set(_ bool: Bool, for key: CKUserDefaults.Key) {}
  func set(_ date: Date, for key: CKUserDefaults.Key) {}
  func array(for key: CKUserDefaults.Key) -> [String]? { return nil }
  func bool(for key: CKUserDefaults.Key) -> Bool { return false }
  func date(for key: CKUserDefaults.Key) -> Date? { return nil }
  func setSelectedCurrency(_ selectedCurrency: SelectedCurrency) {
  }
  func selectedCurrency() -> SelectedCurrency {
    return .BTC
  }

  var unverifyUserWasCalled = false
  func unverifyUser(in context: NSManagedObjectContext) {
    unverifyUserWasCalled = true
  }

  var removeWalletIdWasCalled = false
  func removeWalletId(in context: NSManagedObjectContext) {
    removeWalletIdWasCalled = true
  }

  func findOrCreateDeviceId() -> UUID {
    return UUID()
  }

  func resetPersistence() {}
  func resetWallet() {}
  func walletWords() -> [String]? {
    return keychainManager.retrieveValue(for: .walletWords) as? [String]
  }
  func unverifyAllIdentities() {}
  func persistUnacknowledgedInvitation(in context: NSManagedObjectContext, with btcPair: BitcoinUSDPair,
                                       contact: ContactType, fee: Int, acknowledgementId: String) {}
  func deleteTransactions(notIn txids: [String], in context: NSManagedObjectContext) {}
  func deleteWallet(in context: NSManagedObjectContext) {}
  func set(_ stringValue: CKUserDefaults.Value, for key: CKUserDefaults.Key) {}
  func updateWalletLastIndexes(in context: NSManagedObjectContext) {}
  func deleteDeviceEndpointIds() {}
  func saveCurrentContext() {}
  func getAllInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
    return []
  }

  func matchContactsIfPossible() { databaseManager.matchContactsIfPossible(with: self.contactCacheManager) }
  func verifiedIdentities() -> [UserIdentityType] {
    return []
  }

  var unacknowledgedInvitations: [CKMInvitation] = []
  func getUnacknowledgedInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
    return unacknowledgedInvitations
  }

  func acknowledgeInvitation(with outgoingTransactionData: OutgoingTransactionData,
                             response: WalletAddressRequestResponse,
                             in context: NSManagedObjectContext) {}

  func setDidTutorial(_ boolValue: Bool) {
    let number = NSNumber(value: boolValue)
    self.set(Int(truncating: number), for: .didTutorial)
  }

  func transactionsWithoutDayAveragePrice(in context: NSManagedObjectContext) -> Promise<[CKMTransaction]> {
    return Promise { _ in }
  }

  func backup(recoveryWords words: [String]) {}

  func containsRegularTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
    return (incoming: false, outgoing: false)
  }

  func containsDropbitTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
    return (incoming: false, outgoing: false)
  }

  func persistTemporaryTransaction(
    from transactionData: CNBTransactionData,
    with outgoingTransactionData: OutgoingTransactionData,
    txid: String,
    invitation: CKMInvitation?,
    in context: NSManagedObjectContext) -> CKMTransaction {
    return CKMTransaction(insertInto: context)
  }

  func persistReceivedSharedPayloads(_ payloads: [SharedPayloadV2], kit: PhoneNumberKit, in context: NSManagedObjectContext) { }

  func groomAddressTransactionSummaries(
    from responses: [AddressTransactionSummaryResponse],
    in context: NSManagedObjectContext,
    fullSync: Bool) -> Promise<Void> {
    return Promise { _ in }
  }

  func dustProtectionMinimumAmount() -> Int {
    return userDefaultsManager.dustProtectionMinimumAmount()
  }

  func dustProtectionIsEnabled() -> Bool {
    return false
  }

  func enableDustProtection(_ shouldEnable: Bool) {
  }

  func defaultHeaders(in context: NSManagedObjectContext) -> Promise<DefaultRequestHeaders> {
    return Promise { _ in }
  }

  func string(for key: CKUserDefaults.Key) -> String? {
    return ""
  }

  func verifiedPhoneNumber() -> GlobalPhoneNumber? {
    return nil
  }

  func createBackgroundContext() -> NSManagedObjectContext {
    return databaseManager.createBackgroundContext()
  }

  func mainQueueContext() -> NSManagedObjectContext {
    return databaseManager.mainQueueContext
  }

  func persistentStore() -> NSPersistentStore? {
    return nil
  }

  func persistentStore(for context: NSManagedObjectContext) -> NSPersistentStore? {
    return nil
  }

  func persistTransactionSummaries(
    from responses: [AddressTransactionSummaryResponse],
    in context: NSManagedObjectContext) {}

  func persistWalletId(from response: WalletResponse, in context: NSManagedObjectContext) -> Promise<Void> {
    return Promise { _ in }
  }

  func persistUserId(_ userId: String, in context: NSManagedObjectContext) { }

  func persistAddedWalletAddresses(
    from responses: [WalletAddressResponse],
    metaAddresses: [CNBMetaAddress],
    in context: NSManagedObjectContext) -> Promise<Void> {
    return Promise { _ in }
  }

  func userIsVerified(in context: NSManagedObjectContext) -> Bool {
    return userVerificationStatus(in: context) == .verified
  }

  var userVerificationStatusValue: UserVerificationStatus = .unverified
  func userVerificationStatus(in context: NSManagedObjectContext) -> UserVerificationStatus {
    return userVerificationStatusValue
  }

  func serverPoolAddresses(in context: NSManagedObjectContext) -> [CKMServerAddress] {
    return []
  }

  var addressValuesForReceivedPendingDropBits: [String] = []
  func addressesProvidedForReceivedPendingDropBits(in context: NSManagedObjectContext) -> [String] {
    return addressValuesForReceivedPendingDropBits
  }

  var lastReceiveAddressIndexValue: Int?
  func lastReceiveAddressIndex(in context: NSManagedObjectContext) -> Int? {
    return lastReceiveAddressIndexValue
  }

  func lastChangeAddressIndex(in context: NSManagedObjectContext) -> Int? {
    return 0
  }

  var setLastLoginTimeWasCalled = false
  private var lastTimeEnteredBackground: TimeInterval = Date().timeIntervalSince1970
  func setLastLoginTime() {
    setLastLoginTimeWasCalled = true
    lastTimeEnteredBackground = Date().timeIntervalSince1970
  }

  func setLastMockLogin(timeInterval: TimeInterval) {
    lastTimeEnteredBackground = timeInterval
  }

  var wasAskedForLastLoginTime = false
  func lastLoginTime() -> TimeInterval? {
    wasAskedForLastLoginTime = true
    return lastTimeEnteredBackground
  }

  var walletIdValue: String?
  func walletId(in context: NSManagedObjectContext) -> String? {
    return walletIdValue
  }

  var userIdValue: String?
  func userId(in context: NSManagedObjectContext) -> String? {
    return userIdValue
  }

  func persistVerificationStatus(from response: UserResponse, in context: NSManagedObjectContext) -> Promise<UserVerificationStatus> {
    return Promise { _ in }
  }

  func walletAndUserId(in context: NSManagedObjectContext) -> Promise<(walletId: String, userId: String)> {
    return Promise { _ in }
  }

  func persistUserPublicURLInfo(from response: UserResponse, in context: NSManagedObjectContext) { }
  func getUserPublicURLInfo(in context: NSManagedObjectContext) -> UserPublicURLInfo? {
    return nil
  }

  func deviceEndpointIds() -> DeviceEndpointIds? {
    return nil
  }

  func walletWordsBackedUp() -> Bool {
    return keychainManager.walletWordsBackedUp()
  }

  var persistTransactionsFromTxResponsesWasCalled = false
  func persistTransactions(
    from transactionResponses: [TransactionResponse],
    in context: NSManagedObjectContext,
    relativeToCurrentHeight blockHeight: Int,
    fullSync: Bool
    ) -> Promise<Void> {
    persistTransactionsFromTxResponsesWasCalled = true
    return Promise { _ in }
  }

  func setDatabaseMigrationFlag(migrated: Bool, for version: DatabaseMigrationVersion) {

  }

  func databaseMigrationFlag(for version: DatabaseMigrationVersion) -> Bool {
    return false
  }

  func setKeychainMigrationFlag(migrated: Bool, for version: KeychainMigrationVersion) {

  }

  func keychainMigrationFlag(for version: KeychainMigrationVersion) -> Bool {
    return false
  }

  func setContactCacheMigrationFlag(migrated: Bool, for version: ContactCacheMigrationVersion) {

  }

  func contactCacheMigrationFlag(for version: ContactCacheMigrationVersion) -> Bool {
    return false
  }

  func double(for key: CKUserDefaults.Key) -> Double {
    let userDefaultsManager = self.userDefaultsManager as? MockUserDefaultsManager
    return userDefaultsManager?.value[key.rawValue] as? Double ?? 0.0
  }

  func set(_ doubleValue: Double, for key: CKUserDefaults.Key) {
    let userDefaultsManager = self.userDefaultsManager as? MockUserDefaultsManager
    userDefaultsManager?.value[key.rawValue] = doubleValue
  }

  func integer(for key: CKUserDefaults.Key) -> Int {
    let userDefaultsManager = self.userDefaultsManager as? MockUserDefaultsManager
    return userDefaultsManager?.value[key.rawValue] as? Int ?? 0
  }

  func set(_ integerValue: Int, for key: CKUserDefaults.Key) {
    let userDefaultsManager = self.userDefaultsManager as? MockUserDefaultsManager
    userDefaultsManager?.value[key.rawValue] = integerValue
  }
}
