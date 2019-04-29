//
// Created by BJ Miller on 2/14/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import Foundation
import CoreData
import PromiseKit
import PhoneNumberKit
import os.log

class PersistenceManager: PersistenceManagerType {

  let keychainManager: PersistenceKeychainType
  let databaseManager: PersistenceDatabaseType
  let userDefaultsManager: PersistenceUserDefaultsType
  let contactCacheManager: ContactCacheManagerType

  let hashingManager = HashingManager()

  init(
    keychainManager: PersistenceKeychainType = CKKeychain(),
    databaseManager: PersistenceDatabaseType = CKDatabase(),
    userDefaultsManager: PersistenceUserDefaultsType = CKUserDefaults(),
    contactCacheManager: ContactCacheManagerType = ContactCacheManager()) {
    self.keychainManager = keychainManager
    self.databaseManager = databaseManager
    self.userDefaultsManager = userDefaultsManager
    self.contactCacheManager = contactCacheManager
  }

  func createBackgroundContext() -> NSManagedObjectContext {
    return databaseManager.createBackgroundContext()
  }

  func resetPersistence() {
    self.resetWallet()
    self.userDefaultsManager.deleteAll()
    self.keychainManager.deleteAll()
  }

  func resetWallet() {
    let bgContext = self.createBackgroundContext()
    self.deleteWallet(in: bgContext)
    bgContext.performAndWait {
      _ = CKMWallet.findOrCreate(in: bgContext)
      try? bgContext.save()
    }
  }

  func walletWords() -> [String]? {
    let maybeWords = keychainManager.retrieveValue(for: .walletWords) as? [String]
    if let words = maybeWords, words.count == 12 {
      return words
    }
    return nil
  }

  func mainQueueContext() -> NSManagedObjectContext {
    return databaseManager.mainQueueContext
  }

  func persistentStore() -> NSPersistentStore? {
    return persistentStore(for: mainQueueContext())
  }

  func persistentStore(for context: NSManagedObjectContext) -> NSPersistentStore? {
    return databaseManager.persistentStore(for: context)
  }

  func persistTransactions(
    from transactionResponses: [TransactionResponse],
    in context: NSManagedObjectContext,
    relativeToCurrentHeight blockHeight: Int,
    fullSync: Bool
    ) -> Promise<Void> {
    guard transactionResponses.isNotEmpty else { return Promise.value(()) }
    return databaseManager.persistTransactions(from: transactionResponses, in: context, relativeToCurrentHeight: blockHeight, fullSync: fullSync)
  }

  func persistTemporaryTransaction(
    from transactionData: CNBTransactionData,
    with outgoingTransactionData: OutgoingTransactionData,
    txid: String,
    invitation: CKMInvitation?,
    in context: NSManagedObjectContext
    ) -> CKMTransaction {
    return databaseManager.persistTemporaryTransaction(
      from: transactionData,
      with: outgoingTransactionData,
      txid: txid,
      invitation: invitation,
      in: context
    )
  }

  func containsRegularTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
    return databaseManager.containsRegularTransaction(in: context)
  }

  func containsDropbitTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
    return databaseManager.containsDropbitTransaction(in: context)
  }

  func getUnacknowledgedInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
    return databaseManager.getUnacknowledgedInvitations(in: context)
  }

  func deleteTransactions(notIn txids: [String], in context: NSManagedObjectContext) {
    return databaseManager.deleteTransactions(notIn: txids, in: context)
  }

  func transactionsWithoutDayAveragePrice(in context: NSManagedObjectContext) -> Promise<[CKMTransaction]> {
    return databaseManager.transactionsWithoutDayAveragePrice(in: context)
  }

  func getAllInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
    return databaseManager.getAllInvitations(in: context)
  }

  func persistWalletId(from response: WalletResponse, in context: NSManagedObjectContext) -> Promise<Void> {
    set(stringValue: response.id, for: .walletID)
    return databaseManager.persistWalletId(response.id, in: context)
  }

  /// Will only persist a non-empty string to protect when that is returned by the server for some routes
  func persistUserId(_ userId: String, in context: NSManagedObjectContext) {
    guard userId.isNotEmpty else { return }

    set(stringValue: userId, for: .userID)
    databaseManager.persistUserId(userId, in: context)
  }

  func persistVerificationStatus(from response: UserResponse, in context: NSManagedObjectContext) -> Promise<UserVerificationStatus> {
    return databaseManager.persistVerificationStatus(response.status, in: context)
  }

  /// Call this to reset the user state to match the state of tapping Skip on verification
  func unverifyUser(in context: NSManagedObjectContext) {
    // Perform on both contexts to ensure that willSave/didSave observers receive notification on main queue for badge updates
    databaseManager.unverifyUser(in: context)
    databaseManager.unverifyUser(in: self.mainQueueContext())

    userDefaultsManager.unverifyUser()
    keychainManager.unverifyUser()
  }

  func removeWalletId(in context: NSManagedObjectContext) {
    databaseManager.removeWalletId(in: context)
    userDefaultsManager.removeWalletId()
  }

  func deleteWallet(in context: NSManagedObjectContext) {
    databaseManager.deleteAll(in: context)
    userDefaultsManager.deleteWallet()
    keychainManager.deleteAll()
  }

  func backup(recoveryWords words: [String]) {
    keychainManager.backup(recoveryWords: words)
  }

  func walletWordsBackedUp() -> Bool {
    return keychainManager.walletWordsBackedUp()
  }

  /// The responses should correspond 1-to-1 with the metaAddresses, order is irrelevant.
  func persistAddedWalletAddresses(
    from responses: [WalletAddressResponse],
    metaAddresses: [CNBMetaAddress],
    in context: NSManagedObjectContext) -> Promise<Void> {
    return Promise { seal in

      guard let wallet = CKMWallet.find(in: context) else {
        seal.reject(CKPersistenceError.noManagedWallet)
        return
      }

      var persistencePromises: [Promise<Void>] = []
      for response in responses {
        guard let matchingMetaAddress = metaAddresses.filter({ $0.address == response.address }).first else {
          seal.reject(WalletAddressError.unexpectedAddress)
          return
        }

        let promise = databaseManager.persistServerAddress(for: matchingMetaAddress, createdAt: response.createdAt, wallet: wallet, in: context)
        persistencePromises.append(promise)
      }

      when(fulfilled: persistencePromises)
        .done { seal.fulfill(()) }
        .catch { error in seal.reject(error) }
    }
  }

  func userIsVerified(in context: NSManagedObjectContext) -> Bool {
    return userVerificationStatus(in: context) == .verified
  }

  func userVerificationStatus(in context: NSManagedObjectContext) -> UserVerificationStatus {
    return databaseManager.userVerificationStatus(in: context)
  }

  func serverPoolAddresses(in context: NSManagedObjectContext) -> [CKMServerAddress] {
    return databaseManager.serverPoolAddresses(in: context)
  }

  func updateWalletLastIndexes(in context: NSManagedObjectContext) {
    let lastReceiveIndex = CKMDerivativePath.maxUsedReceiveIndex(in: context)
    let lastChangeIndex = CKMDerivativePath.maxUsedChangeIndex(in: context)
    databaseManager.updateLastReceiveAddressIndex(index: lastReceiveIndex, in: context)
    databaseManager.updateLastChangeAddressIndex(index: lastChangeIndex, in: context)
  }

  func lastReceiveAddressIndex(in context: NSManagedObjectContext) -> Int? {
    return databaseManager.lastReceiveIndex(in: context)
  }

  func lastChangeAddressIndex(in context: NSManagedObjectContext) -> Int? {
    return databaseManager.lastChangeIndex(in: context)
  }

  func deregisterPhone() {
    let context = mainQueueContext()
    databaseManager.unverifyUser(in: context)
    keychainManager.unverifyUser()
    userDefaultsManager.unverifyUser()
  }

  func verifiedPhoneNumber() -> GlobalPhoneNumber? {
    guard let nationalNumber = keychainManager.retrieveValue(for: .phoneNumber) as? String else { return nil }
    let countryCode = keychainManager.retrieveValue(for: .countryCode) as? Int ?? 1 //default to 1 for legacy users
    return GlobalPhoneNumber(countryCode: countryCode, nationalNumber: nationalNumber)
  }

  func persistTransactionSummaries(
    from responses: [AddressTransactionSummaryResponse],
    in context: NSManagedObjectContext) {
    databaseManager.persistTransactionSummaries(from: responses, in: context)
    updateReceiveAddressGaps(in: context)
  }

  private func updateReceiveAddressGaps(in context: NSManagedObjectContext) {
    let usedDerivativePaths = CKMDerivativePath.findAllReceivePathsWithAddressTransactionSummaries(in: context)
    let usedIndexes = usedDerivativePaths.map { $0.index }
    if let maxUsedIndex = usedIndexes.max() {
      let fullSet = Set(Array(0...maxUsedIndex))
      let usedSet = Set(usedIndexes)
      let gaps: Set<Int> = fullSet.subtracting(usedSet)
      self.userDefaultsManager.receiveAddressIndexGaps = gaps

    } else {
      self.userDefaultsManager.receiveAddressIndexGaps = []
    }
  }

  func persistReceivedSharedPayloads(_ payloads: [SharedPayloadV1], kit: PhoneNumberKit, in context: NSManagedObjectContext) {
    let hasher = self.hashingManager
    databaseManager.persistReceivedSharedPayloads(
      payloads,
      hasher: hasher,
      kit: kit,
      contactCacheManager: contactCacheManager,
      in: context)
  }

  func walletId(in context: NSManagedObjectContext) -> String? {
    if let walletID = string(for: .walletID) {
      return walletID
    } else {
      guard let walletID = databaseManager.walletId(in: context) else { return nil }
      self.set(stringValue: walletID, for: .walletID)
      return walletID
    }
  }

  func userId(in context: NSManagedObjectContext) -> String? {
    if let userID = string(for: .userID) {
      return userID
    } else {
      guard let userID = databaseManager.userId(in: context) else { return nil }
      self.set(stringValue: userID, for: .userID)
      return userID
    }
  }

  func walletAndUserId(in context: NSManagedObjectContext) -> Promise<(walletId: String, userId: String)> {
    return Promise { seal in
      guard let walletId = self.walletId(in: context) else { throw CKPersistenceError.missingValue(key: "wallet ID") }
      guard let userId = self.userId(in: context) else { throw CKPersistenceError.missingValue(key: "user ID") }
      seal.fulfill((walletId, userId))
    }
  }

  func defaultHeaders(in context: NSManagedObjectContext) -> Promise<DefaultRequestHeaders> {
    return walletAndUserId(in: context).map { DefaultRequestHeaders(walletId: $0.walletId, userId: $0.userId) }
  }

  func findOrCreateDeviceId() -> UUID {
    if let existingUUID = userDefaultsManager.deviceId() {
      return existingUUID
    } else {
      let newUUID = UUID()
      userDefaultsManager.setDeviceId(newUUID)
      return newUUID
    }
  }

  func deviceEndpointIds() -> DeviceEndpointIds? {
    guard let serverDeviceId = string(for: .coinNinjaServerDeviceId),
      let deviceEndpointId = string(for: .deviceEndpointId) else {
        return nil
    }

    return DeviceEndpointIds(serverDevice: serverDeviceId, endpoint: deviceEndpointId)
  }

  func deleteDeviceEndpointIds() {
    userDefaultsManager.deleteDeviceEndpointIds()
  }

  func setLastLoginTime() {
    _ = keychainManager.store(anyValue: Date().timeIntervalSince1970, key: .lastTimeEnteredBackground)
  }

  func lastLoginTime() -> TimeInterval? {
    return keychainManager.retrieveValue(for: .lastTimeEnteredBackground) as? TimeInterval
  }

  func persist(pendingInvitationData data: PendingInvitationData) {
    userDefaultsManager.persist(pendingInvitationData: data)
  }

  func persistUnacknowledgedInvitation(in context: NSManagedObjectContext, with btcPair: BitcoinUSDPair,
                                       contact: ContactType, fee: Int, acknowledgementId: String) {
    guard let inputs = ManagedPhoneNumberInputs(phoneNumber: contact.globalPhoneNumber) else { return }
    context.performAndWait {
      let phoneNumber = CKMPhoneNumber.findOrCreate(withInputs: inputs,
                                                    phoneNumberHash: contact.phoneNumberHash, in: context)
      let invitation = CKMInvitation(insertInto: context)
      invitation.id = CKMInvitation.unacknowledgementPrefix + acknowledgementId
      invitation.btcAmount = btcPair.btcAmount.asFractionalUnits(of: .BTC)
      invitation.usdAmountAtTimeOfInvitation = btcPair.usdAmount.asFractionalUnits(of: .USD)
      invitation.counterpartyName = contact.displayName
      invitation.counterpartyPhoneNumber = phoneNumber
      invitation.status = .notSent
      invitation.setFlatFee(to: fee)
      self.userDefaultsManager.persist(pendingInvitationData: invitation.pendingInvitationData)
    }
  }

  func pendingInvitations() -> [PendingInvitationData] {
    return userDefaultsManager.pendingInvitations()
  }

  func pendingInvitation(with id: String) -> PendingInvitationData? {
    return userDefaultsManager.pendingInvitation(with: id)
  }

  func removePendingInvitationData(with id: String) -> PendingInvitationData? {
    return userDefaultsManager.removePendingInvitation(with: id)
  }

  func addressesProvidedForReceivedPendingDropBits(in context: NSManagedObjectContext) -> [String] {
    return databaseManager.addressesProvidedForReceivedPendingDropBits(in: context)
  }

  func setDatabaseMigrationFlag(migrated: Bool, for version: DatabaseMigrationVersion) {
    setMigrationFlag(migrated: migrated, version: version.rawValue, key: .migrationVersions)
  }

  func databaseMigrationFlag(for version: DatabaseMigrationVersion) -> Bool {
    return getMigrationFlag(version: version.rawValue, key: .migrationVersions)
  }

  func setKeychainMigrationFlag(migrated: Bool, for version: KeychainMigrationVersion) {
    setMigrationFlag(migrated: migrated, version: version.rawValue, key: .keychainMigrationVersions)
  }

  func keychainMigrationFlag(for version: KeychainMigrationVersion) -> Bool {
    return getMigrationFlag(version: version.rawValue, key: .keychainMigrationVersions)
  }

  func contactCacheMigrationFlag(for version: ContactCacheMigrationVersion) -> Bool {
    return getMigrationFlag(version: version.rawValue, key: .contactCacheMigrationVersions)
  }

  func setContactCacheMigrationFlag(migrated: Bool, for version: ContactCacheMigrationVersion) {
    setMigrationFlag(migrated: migrated, version: version.rawValue, key: .contactCacheMigrationVersions)
  }

  private func getMigrationFlag(version: String, key: CKUserDefaults.Key) -> Bool {
    let value = CKUserDefaults.standardDefaults.value(forKey: key.defaultsString) as? [String: Bool]
    return value?[version] ?? false
  }

  private func setMigrationFlag(migrated: Bool, version: String, key: CKUserDefaults.Key) {
    var value = CKUserDefaults.standardDefaults.value(forKey: key.defaultsString) as? [String: Bool] ?? [:]
    value[version] = migrated
    CKUserDefaults.standardDefaults.setValue(value, forKey: key.defaultsString)
  }

  func acknowledgeInvitation(with outgoingTransactionData: OutgoingTransactionData,
                             response: WalletAddressRequestResponse,
                             in context: NSManagedObjectContext) {
    guard let invitation = CKMInvitation.updateIfExists(withAddressRequestResponse: response,
                                                        side: .sent, isAcknowledged: false, in: context) else { return }
    let transaction = CKMTransaction(insertInto: context)
    transaction.configure(with: outgoingTransactionData, in: context)
    transaction.configureNewSenderSharedPayload(with: outgoingTransactionData.sharedPayloadDTO, in: context)
    invitation.transaction = transaction
    self.persist(pendingInvitationData: invitation.pendingInvitationData)
  }

  func matchContactsIfPossible() {
    databaseManager.matchContactsIfPossible(with: contactCacheManager)
  }

  func dustProtectionMinimumAmount() -> Int {
    return userDefaultsManager.dustProtectionMinimumAmount()
  }

  func dustProtectionIsEnabled() -> Bool {
    return userDefaultsManager.dustProtectionIsEnabled()
  }

  func enableDustProtection(_ shouldEnable: Bool) {
    let key = CKUserDefaults.Key.dustProtectionEnabled.defaultsString
    CKUserDefaults.standardDefaults.set(shouldEnable, forKey: key)
  }

  func double(for key: CKUserDefaults.Key) -> Double {
    return CKUserDefaults.standardDefaults.double(forKey: key.defaultsString)
  }

  func set(_ doubleValue: Double, for key: CKUserDefaults.Key) {
    CKUserDefaults.standardDefaults.set(doubleValue, forKey: key.defaultsString)
  }

  func integer(for key: CKUserDefaults.Key) -> Int {
    return CKUserDefaults.standardDefaults.integer(forKey: key.defaultsString)
  }

  func set(_ integerValue: Int, for key: CKUserDefaults.Key) {
    CKUserDefaults.standardDefaults.set(integerValue, forKey: key.defaultsString)
  }

  func string(for key: CKUserDefaults.Key) -> String? {
    return CKUserDefaults.standardDefaults.string(forKey: key.defaultsString)
  }

  func array(for key: CKUserDefaults.Key) -> [String]? {
    guard let array = CKUserDefaults.standardDefaults.array(forKey: key.defaultsString) as? [String] else {
      return nil
    }

    return array
  }

  func set(_ array: [String], for key: CKUserDefaults.Key) {
    CKUserDefaults.standardDefaults.set(array, forKey: key.defaultsString)
  }

  func set(_ string: String, for key: CKUserDefaults.Key) {
    CKUserDefaults.standardDefaults.set(string, forKey: key.defaultsString)
  }

  func set(_ stringValue: CKUserDefaults.Value, for key: CKUserDefaults.Key) {
    set(stringValue.defaultsString, for: key)
  }

  func set(stringValue: String, for key: CKUserDefaults.Key) {
    CKUserDefaults.standardDefaults.set(stringValue, forKey: key.defaultsString)
  }

  func set(_ bool: Bool, for key: CKUserDefaults.Key) {
    CKUserDefaults.standardDefaults.set(bool, forKey: key.defaultsString)
  }

  func bool(for key: CKUserDefaults.Key) -> Bool {
    return CKUserDefaults.standardDefaults.bool(forKey: key.defaultsString)
  }

  func set(_ date: Date, for key: CKUserDefaults.Key) {
    CKUserDefaults.standardDefaults.set(date, forKey: key.defaultsString)
  }

  func date(for key: CKUserDefaults.Key) -> Date? {
    return CKUserDefaults.standardDefaults.object(forKey: key.defaultsString) as? Date
  }

  func setSelectedCurrency(_ selectedCurrency: SelectedCurrency) {
    set(stringValue: selectedCurrency.description, for: CKUserDefaults.Key.selectedCurrency)
  }

  func selectedCurrency() -> SelectedCurrency {
    let stringValue = CKUserDefaults.standardDefaults.value(forKey: CKUserDefaults.Key.selectedCurrency.defaultsString) as? String
    return stringValue.flatMap { SelectedCurrency(rawValue: $0) } ?? .fiat
  }

}
