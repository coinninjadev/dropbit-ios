//
// Created by BJ Miller on 2/14/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import Foundation
import Strongbox
import CoreData
import PromiseKit
import PhoneNumberKit
import os.log

// swiftlint:disable type_body_length
// swiftlint:disable file_length
class PersistenceManager: PersistenceManagerType {

  let keychainManager: PersistenceKeychainType
  let databaseManager: PersistenceDatabaseType
  let userDefaultsManager: PersistenceUserDefaultsType
  let contactCacheManager: ContactCacheManagerType

  let hashingManager = HashingManager()

  init(
    keychainManager: PersistenceKeychainType = Keychain(),
    databaseManager: PersistenceDatabaseType = Database(),
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
    ) {
    databaseManager.persistTemporaryTransaction(
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

  func persistUserId(from response: UserResponse, in context: NSManagedObjectContext) -> Promise<CKMUser> {
    let userId = response.id
    set(stringValue: userId, for: .userID)
    return databaseManager.persistUserId(userId, in: context)
  }

  func persistVerificationStatus(from response: UserResponse, in context: NSManagedObjectContext) -> Promise<UserVerificationStatus> {
    return databaseManager.persistVerificationStatus(response.status, in: context)
  }

  /// Call this to reset the user state to match the state of tapping Skip on verification
  func unverifyUser(in context: NSManagedObjectContext) {
    databaseManager.unverifyUser(in: context)
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
    let context = createBackgroundContext()
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
    in context: NSManagedObjectContext
    ) -> Promise<Void> {
    return databaseManager.persistTransactionSummaries(from: responses, in: context)
      .get { self.userDefaultsManager.receiveAddressIndexGaps = $0 }.asVoid()
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

  private func getMigrationFlag(version: String, key: CKUserDefaults.Key) -> Bool {
    let value = CKUserDefaults.standardDefaults.value(forKey: key.defaultsString) as? [String: Bool]
    return value?[version] ?? false
  }

  private func setMigrationFlag(migrated: Bool, version: String, key: CKUserDefaults.Key) {
    let value = [version: migrated]
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

  class Keychain: PersistenceKeychainType {

    enum Key: String, CaseIterable {
      case userPin
      case deviceID
      case walletWords
      case walletWordsBackedUp // Bool as NSNumber
      case skippedVerification // Bool as NSNumber
      case lastTimeEnteredBackground
      case countryCode
      case phoneNumber
      case lockoutDate
    }

    private var tempWordStorage: [String]?
    private var tempPinHashStorage: String?

    let store: KeychainAccessorType

    required init(store: KeychainAccessorType = Strongbox()) {
      self.store = store
    }

    @discardableResult
    func store(anyValue value: Any?, key: PersistenceManager.Keychain.Key) -> Bool {
      return store.archive(value, key: key.rawValue)
    }

    @discardableResult
    func store(valueToHash value: String?, key: PersistenceManager.Keychain.Key) -> Bool {
      return store.archive(value?.sha256(), key: key.rawValue)
    }

    @discardableResult
    func store(deviceID: String) -> Bool {
      return store.archive(deviceID, key: PersistenceManager.Keychain.Key.deviceID.rawValue)
    }

    func backup(recoveryWords words: [String]) {
      _ = store.archive(words, key: PersistenceManager.Keychain.Key.walletWords.rawValue)
    }

    @discardableResult
    func store(recoveryWords words: [String]) -> Bool {
      if let pin = tempPinHashStorage { // store pin and wallet together
        _ = store.archive(pin, key: PersistenceManager.Keychain.Key.userPin.rawValue)
        tempPinHashStorage = nil
        return store.archive(words, key: PersistenceManager.Keychain.Key.walletWords.rawValue)
      } else {
        tempWordStorage = words
        return false
      }
    }

    func walletWordsBackedUp() -> Bool {
      return bool(for: .walletWordsBackedUp) ?? false
    }

    @discardableResult
    func store(userPin pin: String) -> Bool {
      let pinHash = pin.sha256()

      if let words = tempWordStorage { // store pin and wallet together
        _ = store.archive(words, key: PersistenceManager.Keychain.Key.walletWords.rawValue)
        tempWordStorage = nil
        return store.archive(pinHash, key: PersistenceManager.Keychain.Key.userPin.rawValue)
      } else {
        tempPinHashStorage = pinHash
        return false
      }
    }

    func retrieveValue(for key: PersistenceManager.Keychain.Key) -> Any? {
      return store.unarchive(objectForKey: key.rawValue)
    }

    func bool(for key: PersistenceManager.Keychain.Key) -> Bool? {
      return store.unarchive(objectForKey: key.rawValue) as? Bool
    }

    func deleteAll() {
      Key.allCases.forEach { self.store(anyValue: nil, key: $0) }
    }

    func unverifyUser() {
      self.store(anyValue: nil, key: .countryCode)
      self.store(anyValue: nil, key: .phoneNumber)

      // Prevent reprompting user to verify on next launch
      self.store(anyValue: true, key: .skippedVerification)
    }

  } // end Keychain class

  class CKUserDefaults: PersistenceUserDefaultsType {

    enum Value: String {
      case optIn
      case optOut

      var defaultsString: String { return self.rawValue }
    }

    enum Key: String, CaseIterable {
      case invitationPopup
      case firstTimeOpeningApp
      case exchangeRateBTCUSD
      case feeBest
      case feeBetter
      case feeGood
      case blockheight
      case didTutorial
      case walletID // for background fetching purposes
      case userID   // for background fetching purposes
      case pendingInvitations  // [String: [String: Data]]
      case uuid // deviceID
      case shownMessageIds
      case lastPublishedMessageTimeInterval
      case coinNinjaServerDeviceId
      case receiveAddressIndexGaps
      case deviceEndpointId
      case devicePushToken
      case unseenTransactionChangesExist
      case backupWordsReminderShown
      case migrationVersions //database
      case keychainMigrationVersions
      case lastSuccessfulSyncCompletedAt

      var defaultsString: String { return self.rawValue }
    }

    private func removeValue(forKey key: Key) {
      CKUserDefaults.standardDefaults.set(nil, forKey: key.defaultsString)
    }

    private func removeValues(forKeys keys: [Key]) {
      keys.forEach { removeValue(forKey: $0) }
    }

    func deviceId() -> UUID? {
      guard let deviceIdString = CKUserDefaults.standardDefaults.string(forKey: Key.uuid.defaultsString) else { return nil }
      return UUID(uuidString: deviceIdString)
    }

    func setDeviceId(_ uuid: UUID) {
      CKUserDefaults.standardDefaults.set(uuid.uuidString, forKey: Key.uuid.defaultsString)
    }

    func deleteDeviceEndpointIds() {
      removeValues(forKeys: [
        .deviceEndpointId,
        .coinNinjaServerDeviceId
        ])
    }

    /// Use this method to not delete everything from UserDefaults
    func deleteWallet() {
      removeValues(forKeys: [
        .exchangeRateBTCUSD,
        .feeBest,
        .feeBetter,
        .feeGood,
        .didTutorial,
        .blockheight,
        .receiveAddressIndexGaps,
        .walletID,
        .unseenTransactionChangesExist,
        .userID,
        .pendingInvitations,
        .backupWordsReminderShown,
        .unseenTransactionChangesExist,
        .lastSuccessfulSyncCompletedAt
        ])
      CKUserDefaults.standardDefaults.synchronize()
    }

    func deleteAll() {
      removeValues(forKeys: Key.allCases)
    }

    func removeWalletId() {
      removeValue(forKey: .walletID)
    }

    func unverifyUser() {
      removeValues(forKeys: [.pendingInvitations, .userID])
    }

    let indexGapKey = CKUserDefaults.Key.receiveAddressIndexGaps.rawValue
    var receiveAddressIndexGaps: Set<Int> {
      get {
        if let gaps = CKUserDefaults.standardDefaults.array(forKey: indexGapKey) as? [Int] {
          return Set(gaps)
        } else {
          return Set<Int>()
        }
      }
      set {
        let numbers: [NSNumber] = Array(newValue).map { NSNumber(value: $0) } // map Set<Int> to [NSNumber]
        CKUserDefaults.standardDefaults.set(NSArray(array: numbers), forKey: indexGapKey)
      }
    }

    func persist(pendingInvitationData invitationData: PendingInvitationData) {
      guard let data = invitationData.asData() else { return }
      let pendingKey = CKUserDefaults.Key.pendingInvitations.defaultsString
      var existing: [String: Data] = [:]
      if let value = CKUserDefaults.standardDefaults.dictionary(forKey: pendingKey) as? [String: Data] {
        existing = value
      }
      let toMerge: [String: Data] = [invitationData.id: data]
      let merged = existing.merging(toMerge, uniquingKeysWith: { (_, new) in new })
      CKUserDefaults.standardDefaults.set(merged, forKey: pendingKey)
    }

    func pendingInvitations() -> [PendingInvitationData] {
      let pendingKey = CKUserDefaults.Key.pendingInvitations.defaultsString
      guard let pendingInvitations = CKUserDefaults.standardDefaults.dictionary(forKey: pendingKey) as? [String: Data] else { return [] }
      return pendingInvitations.values.compactMap { PendingInvitationData.decode(from: $0) }
    }

    func pendingInvitation(with id: String) -> PendingInvitationData? {
      let pendingKey = CKUserDefaults.Key.pendingInvitations.defaultsString
      guard let pendingInvitations = CKUserDefaults.standardDefaults.dictionary(forKey: pendingKey) as? [String: Data] else { return nil }
      return pendingInvitations[id].flatMap { PendingInvitationData.decode(from: $0) }
    }

    @discardableResult
    func removePendingInvitation(with id: String) -> PendingInvitationData? {
      let pendingKey = CKUserDefaults.Key.pendingInvitations.defaultsString
      var existing: [String: Data] = [:]
      if let value = CKUserDefaults.standardDefaults.dictionary(forKey: pendingKey) as? [String: Data] {
        existing = value
      }
      let removed = existing.removeValue(forKey: id).flatMap { PendingInvitationData.decode(from: $0) }
      CKUserDefaults.standardDefaults.set(existing, forKey: pendingKey)
      return removed
    }

    func setPendingInvitationFailed(_ invitation: PendingInvitationData) {
      var newInvitation = invitation
      newInvitation.failedToSendAt = Date()
      guard let data = newInvitation.asData() else { return }

      let pendingKey = CKUserDefaults.Key.pendingInvitations.defaultsString
      var existing: [String: Data] = [:]
      if let value = CKUserDefaults.standardDefaults.dictionary(forKey: pendingKey) as? [String: Data] {
        existing = value
      }

      existing[invitation.id] = data

      CKUserDefaults.standardDefaults.set(existing, forKey: pendingKey)
    }
  } // end CKUserDefaults class

  private func save() {
    CKUserDefaults.standardDefaults.synchronize()
  }

  func double(for key: PersistenceManager.CKUserDefaults.Key) -> Double {
    return CKUserDefaults.standardDefaults.double(forKey: key.defaultsString)
  }

  func set(_ doubleValue: Double, for key: PersistenceManager.CKUserDefaults.Key) {
    CKUserDefaults.standardDefaults.set(doubleValue, forKey: key.defaultsString)
  }

  func integer(for key: PersistenceManager.CKUserDefaults.Key) -> Int {
    return CKUserDefaults.standardDefaults.integer(forKey: key.defaultsString)
  }

  func set(_ integerValue: Int, for key: PersistenceManager.CKUserDefaults.Key) {
    CKUserDefaults.standardDefaults.set(integerValue, forKey: key.defaultsString)
  }

  func string(for key: PersistenceManager.CKUserDefaults.Key) -> String? {
    return CKUserDefaults.standardDefaults.string(forKey: key.defaultsString)
  }

  func array(for key: PersistenceManager.CKUserDefaults.Key) -> [String]? {
    guard let array = CKUserDefaults.standardDefaults.array(forKey: key.defaultsString) as? [String] else {
      return nil
    }

    return array
  }

  func set(_ array: [String], for key: PersistenceManager.CKUserDefaults.Key) {
    CKUserDefaults.standardDefaults.set(array, forKey: key.defaultsString)
  }

  func set(_ string: String, for key: PersistenceManager.CKUserDefaults.Key) {
    CKUserDefaults.standardDefaults.set(string, forKey: key.defaultsString)
  }

  func set(_ stringValue: PersistenceManager.CKUserDefaults.Value, for key: PersistenceManager.CKUserDefaults.Key) {
    set(stringValue.defaultsString, for: key)
  }

  func set(stringValue: String, for key: PersistenceManager.CKUserDefaults.Key) {
    CKUserDefaults.standardDefaults.set(stringValue, forKey: key.defaultsString)
  }

  func set(_ bool: Bool, for key: PersistenceManager.CKUserDefaults.Key) {
    CKUserDefaults.standardDefaults.set(bool, forKey: key.defaultsString)
  }

  func bool(for key: PersistenceManager.CKUserDefaults.Key) -> Bool {
    return CKUserDefaults.standardDefaults.bool(forKey: key.defaultsString)
  }

  func set(_ date: Date, for key: PersistenceManager.CKUserDefaults.Key) {
    CKUserDefaults.standardDefaults.set(date, forKey: key.defaultsString)
  }

  func date(for key: PersistenceManager.CKUserDefaults.Key) -> Date? {
    return CKUserDefaults.standardDefaults.object(forKey: key.defaultsString) as? Date
  }

}
