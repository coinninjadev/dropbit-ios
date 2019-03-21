//
// Created by BJ Miller on 2/14/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import CoreData
import PhoneNumberKit
import PromiseKit
@testable import DropBit

// swiftlint:disable file_length
// swiftlint:disable type_body_length
class MockPersistenceManager: PersistenceManagerType {

  var keychainManager: PersistenceKeychainType
  var databaseManager: PersistenceDatabaseType
  var userDefaultsManager: PersistenceUserDefaultsType
  var contactCacheManager: ContactCacheManagerType
  var hashingManager: HashingManager = HashingManager()

  init(keychainManager: PersistenceKeychainType = MockPersistenceKeychainManager(store: MockKeychainAccessorType()),
       databaseManager: PersistenceDatabaseType = MockPersistenceDatabaseManager(),
       userDefaultsManager: PersistenceUserDefaultsType = MockPersistenceUserDefaultsManager(),
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
  func deregisterPhone() {}
  func persist(pendingInvitationData data: PendingInvitationData) {}
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

  func removePendingInvitationData(with id: String) -> PendingInvitationData? {
    return nil
  }

  func backup(recoveryWords words: [String]) {}

  func pendingInvitations() -> [PendingInvitationData] {
    return []
  }

  func pendingInvitation(with id: String) -> PendingInvitationData? {
    return nil
  }

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
    in context: NSManagedObjectContext) { }

  func persistReceivedSharedPayloads(_ payloads: [SharedPayloadV1], kit: PhoneNumberKit, in context: NSManagedObjectContext) { }

  func groomAddressTransactionSummaries(
    from responses: [AddressTransactionSummaryResponse],
    in context: NSManagedObjectContext,
    fullSync: Bool) -> Promise<Void> {
    return Promise { _ in }
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
    in context: NSManagedObjectContext) -> Promise<Void> {
    return Promise { _ in }
  }

  func persistWalletId(from response: WalletResponse, in context: NSManagedObjectContext) -> Promise<Void> {
    return Promise { _ in }
  }

  func persistUserId(from response: UserResponse, in context: NSManagedObjectContext) -> Promise<CKMUser> {
    return Promise { _ in }
  }

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

  // MARK: KeychainManager
  class MockPersistenceKeychainManager: PersistenceKeychainType {
    func backup(recoveryWords words: [String]) {}
    func deleteAll() {}
    func unverifyUser() {}

    func bool(for key: CKKeychain.Key) -> Bool? {
      return nil
    }

    func walletWordsBackedUp() -> Bool {
      return bool(for: .walletWordsBackedUp) ?? false
    }

    required init(store: KeychainAccessorType) { }

    var valueExists = false
    var values: [String: Any] = [:]
    var anyValueExists = false

    func store(anyValue value: Any?, key: CKKeychain.Key) -> Bool {
      self.values[key.rawValue] = value
      anyValueExists = (self.values[key.rawValue] != nil)
      return anyValueExists
    }
    func store(valueToHash value: String?, key: CKKeychain.Key) -> Bool {
      self.values[key.rawValue] = value
      valueExists = (self.values[key.rawValue] != nil)
      return valueExists
    }

    var wordsExist = false
    func store(recoveryWords words: [String]) -> Bool {
      self.values[CKKeychain.Key.walletWords.rawValue] = words
      wordsExist = !words.isEmpty
      return wordsExist
    }

    var userPinExists = false
    func store(userPin: String) -> Bool {
      return true
    }

    var deviceIDExists = false
    func store(deviceID: String) -> Bool {
      self.values[CKKeychain.Key.deviceID.rawValue] = deviceID
      deviceIDExists = !deviceID.isEmpty
      return deviceIDExists
    }

    func retrieveValue(for key: CKKeychain.Key) -> Any? {
      return values[key.rawValue]
    }

  }

  class MockPersistenceDatabaseManager: PersistenceDatabaseType {

    func persistTemporaryTransaction(
      from transactionData: CNBTransactionData,
      with outgoingTransactionData: OutgoingTransactionData,
      txid: String,
      invitation: CKMInvitation?,
      in context: NSManagedObjectContext) { }

    func groomAddressTransactionSummaries(
      from responses: [AddressTransactionSummaryResponse],
      in context: NSManagedObjectContext,
      fullSync: Bool) -> Promise<Void> {
      return Promise { _ in }
    }

    func getAllInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
      return []
    }

    func getUnacknowledgedInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
      return []
    }

    func deleteTransactions(notIn txids: [String], in context: NSManagedObjectContext) { }
    func unverifyUser(in context: NSManagedObjectContext) { }

    func removeWalletId(in context: NSManagedObjectContext) { }

    func transactionsWithoutDayAveragePrice(in context: NSManagedObjectContext) -> Promise<[CKMTransaction]> {
      return Promise { _ in }
    }

    var inMemoryCoreDataStack = InMemoryCoreDataStack()

    func createBackgroundContext() -> NSManagedObjectContext {
      return inMemoryCoreDataStack.context
    }

    func persistentStore(for context: NSManagedObjectContext) -> NSPersistentStore? {
      return nil
    }

    func containsRegularTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
      return (incoming: false, outgoing: false)
    }

    func containsDropbitTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
      return (incoming: false, outgoing: false)
    }

    func deleteAll(in context: NSManagedObjectContext) {}
    func updateLastReceiveAddressIndex(index: Int, in context: NSManagedObjectContext) {}
    func updateLastChangeAddressIndex(index: Int, in context: NSManagedObjectContext) {}

    func userVerificationStatus(in context: NSManagedObjectContext) -> UserVerificationStatus {
      return .unverified
    }

    func persistWalletId(_ id: String, in context: NSManagedObjectContext) -> Promise<Void> {
      return Promise { _ in }
    }

    func persistUserId(_ id: String, in context: NSManagedObjectContext) -> Promise<CKMUser> {
      return Promise { _ in }
    }

    func walletId(in context: NSManagedObjectContext) -> String? {
      return nil
    }

    func userId(in context: NSManagedObjectContext) -> String? {
      return nil
    }

    func persistVerificationStatus(_ status: String, in context: NSManagedObjectContext) -> Promise<UserVerificationStatus> {
      return Promise { _ in }
    }

    func walletAndUserId(in context: NSManagedObjectContext) -> Promise<(walletId: String, userId: String)> {
      return Promise { _ in }
    }

    func persistTransactions(
      from transactionResponses: [TransactionResponse],
      in context: NSManagedObjectContext,
      relativeToCurrentHeight blockHeight: Int,
      fullSync: Bool
      ) -> Promise<Void> {
      return Promise { _ in }
    }

    func persistTransactionSummaries(
      from responses: [AddressTransactionSummaryResponse],
      in context: NSManagedObjectContext
      ) -> Promise<Set<Int>> {
      return Promise { _ in }
    }

    func persistReceivedSharedPayloads(_ payloads: [SharedPayloadV1],
                                       hasher: HashingManager,
                                       kit: PhoneNumberKit,
                                       contactCacheManager: ContactCacheManagerType,
                                       in context: NSManagedObjectContext) {
    }

    var mainQueueContext: NSManagedObjectContext {
      return inMemoryCoreDataStack.context
    }

    func persistServerAddress(
      for metaAddress: CNBMetaAddress,
      createdAt: Date,
      wallet: CKMWallet,
      in context: NSManagedObjectContext) -> Promise<Void> {
      return Promise { _ in }
    }

    func serverPoolAddresses(in context: NSManagedObjectContext) -> [CKMServerAddress] {
      return []
    }

    func addressesProvidedForReceivedPendingDropBits(in context: NSManagedObjectContext) -> [String] {
      return []
    }

    func lastReceiveIndex(in context: NSManagedObjectContext) -> Int? {
      return 0
    }

    func lastChangeIndex(in context: NSManagedObjectContext) -> Int? {
      return 0
    }

    func matchContactsIfPossible(with contactCacheManager: ContactCacheManagerType) {}
  }

  class MockPersistenceUserDefaultsManager: PersistenceUserDefaultsType {

    func deviceId() -> UUID? {
      return UUID()
    }

    func setDeviceId(_ uuid: UUID) {}
    func deleteDeviceEndpointIds() {}
    func unverifyUser() {}
    func deleteWallet() {}
    func deleteAll() {}
    func removeWalletId() {}
    func setPendingInvitationFailed(_ invitation: PendingInvitationData) { }

    var removePendingInvitationsWasCalled = false
    func removePendingInvitation(with id: String) -> PendingInvitationData? {
      removePendingInvitationsWasCalled = true
      return nil
    }

    var pendingInvitationWithIDWasCalled = false
    func pendingInvitation(with id: String) -> PendingInvitationData? {
      pendingInvitationWithIDWasCalled = true
      return nil
    }

    var deleteAllWasCalled = false
    func deleteAll(in context: NSManagedObjectContext) {
      deleteAllWasCalled = true
    }

    var persistPendingInvitationDataWasCalled = false
    func persist(pendingInvitationData data: PendingInvitationData) {
      persistPendingInvitationDataWasCalled = true
    }

    var getAllPendingInvitationsWasCalled = false
    func pendingInvitations() -> [PendingInvitationData] {
      getAllPendingInvitationsWasCalled = true
      return []
    }

    var receiveAddressIndexGapsValue: Set<Int> = []
    var receiveAddressIndexGaps: Set<Int> {
      get {
        return receiveAddressIndexGapsValue
      }
      set {
        receiveAddressIndexGapsValue = newValue
      }
    }

    // standardDefaults is not used by MockPersistenceManager, and is not accessed outside PersistenceManager (wjf, 2018-04)
    var standardDefaults = UserDefaults(suiteName: "com.coinninja.unittests")
    var value: [String: Any] = [:]
  }

  func double(for key: CKUserDefaults.Key) -> Double {
    let userDefaultsManager = self.userDefaultsManager as? MockPersistenceUserDefaultsManager
    return userDefaultsManager?.value[key.rawValue] as? Double ?? 0.0
  }

  func set(_ doubleValue: Double, for key: CKUserDefaults.Key) {
    let userDefaultsManager = self.userDefaultsManager as? MockPersistenceUserDefaultsManager
    userDefaultsManager?.value[key.rawValue] = doubleValue
  }

  func integer(for key: CKUserDefaults.Key) -> Int {
    let userDefaultsManager = self.userDefaultsManager as? MockPersistenceUserDefaultsManager
    return userDefaultsManager?.value[key.rawValue] as? Int ?? 0
  }

  func set(_ integerValue: Int, for key: CKUserDefaults.Key) {
    let userDefaultsManager = self.userDefaultsManager as? MockPersistenceUserDefaultsManager
    userDefaultsManager?.value[key.rawValue] = integerValue
  }
}

class MockKeychainAccessorType: KeychainAccessorType {
  var wasAskedToArchive = false
  var wasAskedToUnarchive = false

  var value: [String: Any] = [:]

  func archive(_ value: Any?, key: String) -> Bool {
    wasAskedToArchive = true
    self.value[key] = value
    return true
  }

  func unarchive(objectForKey: String) -> Any? {
    wasAskedToUnarchive = true
    return self.value[objectForKey]
  }
}
