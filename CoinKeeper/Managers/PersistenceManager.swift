//
// Created by BJ Miller on 2/14/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import Foundation
import Strongbox
import CoreData
import PromiseKit
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
        seal.reject(CKPersistenceError.noWallet)
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

  func persistReceivedSharedPayloads(_ payloads: [SharedPayloadV1], in context: NSManagedObjectContext) {
    let hasher = self.hashingManager
    databaseManager.persistReceivedSharedPayloads(payloads, hasher: hasher, in: context)
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

  class Database: NSPersistentContainer, PersistenceDatabaseType {

    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "database")

    static var model: NSManagedObjectModel? = {
      return Bundle(for: PersistenceManager.self).url(forResource: "Model", withExtension: "momd")
        .flatMap { NSManagedObjectModel(contentsOf: $0) }
    }()

    static let modelFilename = "CoinNinjaDB"

    lazy var mainQueueContext: NSManagedObjectContext = {
      return self.createNewMainContext()
    }()

    func createBackgroundContext() -> NSManagedObjectContext {
      let bgContext = newBackgroundContext()
      bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
      return bgContext
    }

    func persistentStore(for context: NSManagedObjectContext) -> NSPersistentStore? {
      return context.persistentStoreCoordinator?.persistentStores.first
    }

    private func executeBatchDeleteFor(entity name: String, in context: NSManagedObjectContext) {
      let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
      let request = NSBatchDeleteRequest(fetchRequest: fetch)
      request.resultType = .resultTypeObjectIDs

      context.performAndWait {
        do {
          if let result = try context.execute(request) as? NSBatchDeleteResult, let objectIDs = result.result as? [NSManagedObjectID] {
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: objectIDs], into: [context])
          }
        } catch {
          fatalError("Failed to execute request: \(error)")
        }
      }
    }

    func deleteAll(in context: NSManagedObjectContext) {
      context.performAndWait {
        Database.model?.entities.compactMap { $0.name }.forEach { executeBatchDeleteFor(entity: $0, in: context) }
      }
    }

    func unverifyUser(in context: NSManagedObjectContext) {
      var user: CKMUser?

      context.performAndWait {
        let allServerAddresses = serverPoolAddresses(in: context)
        allServerAddresses.forEach { context.delete($0) }

        CKMInvitation.find(withStatuses: [.requestSent, .addressSent], in: context).forEach { $0.status = .canceled }
        CKMInvitation.find(withStatuses: [.notSent], in: context).forEach { context.delete($0) }

        user = CKMUser.find(in: context)
        user.flatMap { context.delete($0) }

        do {
          try context.save()
        } catch {
          os_log("failed to save context in %@. error: %@", log: logger, type: .error, #function, error.localizedDescription)
        }
      }

      user.map { self.mainQueueContext.refresh($0, mergeChanges: true) }
    }

    func removeWalletId(in context: NSManagedObjectContext) {
      guard let wallet = CKMWallet.find(in: context) else {
        return
      }

      wallet.id = nil
    }

    convenience init() {
      guard let theModel = Database.model else { fatalError("could not load model file") }
      self.init(name: Database.modelFilename, managedObjectModel: theModel)
      setupPersistentStores()
    }

    private func setupPersistentStores() {
      let directory = NSPersistentContainer.defaultDirectoryURL()
      let storeURL = directory.appendingPathComponent("\(Database.modelFilename).sqlite")
      let description = NSPersistentStoreDescription(url: storeURL)
      description.shouldInferMappingModelAutomatically = true
      description.shouldMigrateStoreAutomatically = true
      description.setOption(FileProtectionType.completeUntilFirstUserAuthentication as NSObject, forKey: NSPersistentStoreFileProtectionKey)
      persistentStoreDescriptions = [description]

      self.loadPersistentStores { [weak self] _, error in
        guard let strongSelf = self else { fatalError("could not load persistent store") }
        if let err = error {
          os_log("Failed to load persistence stores: %@", log: strongSelf.logger, type: .error, err.localizedDescription)
        }
        let context = strongSelf.mainQueueContext
        context.performAndWait {
          CKMWallet.findOrCreate(in: context)
          try? context.save()
        }
      }
    }

    func createNewMainContext() -> NSManagedObjectContext {
      let context = viewContext
      context.automaticallyMergesChangesFromParent = true
      context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
      try? context.setQueryGenerationFrom(.current)
      return context
    }

    func walletId(in context: NSManagedObjectContext) -> String? {
      var id: String?

      context.performAndWait {
        id = CKMWallet.find(in: context)?.id
      }

      return id
    }

    func persistWalletId(_ id: String, in context: NSManagedObjectContext) -> Promise<Void> {
      return Promise { seal in
        context.performAndWait {
          guard let wallet = CKMWallet.find(in: context) else {
            seal.reject(CKPersistenceError.noWallet)
            return
          }

          wallet.id = id

          do {
            try context.save()
            seal.fulfill(())
          } catch {
            seal.reject(error)
          }
        }
      }
    }

    func containsRegularTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
      return CKMTransaction.containsRegularTransaction(in: context)
    }

    func containsDropbitTransaction(in context: NSManagedObjectContext) -> IncomingOutgoingTuple {
      return CKMTransaction.containsDropbitTransaction(in: context)
    }

    func userId(in context: NSManagedObjectContext) -> String? {
      return CKMUser.find(in: context)?.id
    }

    func userVerificationStatus(in context: NSManagedObjectContext) -> UserVerificationStatus {
      return CKMUser.find(in: context)?.verificationStatusCase ?? .unverified
    }

    func persistUserId(_ id: String, in context: NSManagedObjectContext) -> Promise<CKMUser> {
      return Promise { seal in
        context.performAndWait {
          let user = CKMUser.updateOrCreate(with: id, in: context)
          do {
            try context.save()
            seal.fulfill(user)
          } catch {
            os_log("Failed to save context with user ID: %@", log: logger, type: .error, error.localizedDescription)
            seal.reject(error)
          }
        }
      }
    }

    func persistVerificationStatus(_ status: String, in context: NSManagedObjectContext) -> Promise<UserVerificationStatus> {
      return Promise { seal in
        context.performAndWait {
          guard let user = CKMUser.find(in: context) else {
            seal.reject(CKPersistenceError.noUser)
            return
          }

          user.verificationStatus = status

          seal.fulfill(user.verificationStatusCase)

        }
      }
    }

    func persistServerAddress(
      for metaAddress: CNBMetaAddress,
      createdAt: Date,
      wallet: CKMWallet,
      in context: NSManagedObjectContext) -> Promise<Void> {
      return Promise { seal in
        let addressString = metaAddress.address
        let index = metaAddress.derivationPath.index

        context.performAndWait {
          let newAddress = CKMServerAddress(address: addressString, createdAt: createdAt, insertInto: context)
          newAddress.derivativePath = CKMDerivativePath.findOrCreate(withIndex: Int(index), in: context)
        }

        seal.fulfill(()) //no need to return the created object(s), fulfill with Void
      }
    }

    func persistTransactions(
      from transactionResponses: [TransactionResponse],
      in context: NSManagedObjectContext,
      relativeToCurrentHeight blockHeight: Int,
      fullSync: Bool
      ) -> Promise<Void> {
      return Promise { seal in
        transactionResponses.forEach {
          _ = CKMTransaction.findOrCreate(with: $0, in: context, relativeToBlockHeight: blockHeight, fullSync: fullSync)
        }
        seal.fulfill(())
      }
    }

    func persistReceivedSharedPayloads(_ payloads: [SharedPayloadV1], hasher: HashingManager, in context: NSManagedObjectContext) {
      let salt: Data
      do {
        salt = try hasher.salt()
      } catch {
        os_log("Failed to get salt for hashing shared payload phone number: %@", log: logger, type: .error, error.localizedDescription)
        return
      }

      for payload in payloads {
        guard let tx = CKMTransaction.find(byTxid: payload.txid, in: context) else { continue }

        if tx.memo == nil {
          tx.memo = payload.info.memo
        }

        let phoneNumber = payload.profile.globalPhoneNumber()
        let phoneNumberHash = hasher.hash(phoneNumber: phoneNumber, salt: salt)

        if tx.phoneNumber == nil, let inputs = ManagedPhoneNumberInputs(phoneNumber: phoneNumber) {
          tx.phoneNumber = CKMPhoneNumber.findOrCreate(withInputs: inputs,
                                                       phoneNumberHash: phoneNumberHash,
                                                       in: context)
        }

        let payloadAsData = try? payload.encoded()
        let ckmSharedPayload = CKMTransactionSharedPayload(sharingDesired: true,
                                                           fiatAmount: payload.info.amount,
                                                           fiatCurrency: payload.info.currency,
                                                           receivedPayload: payloadAsData,
                                                           insertInto: context)
        tx.sharedPayload = ckmSharedPayload
      }
    }

    func persistTransactionSummaries(
      from responses: [AddressTransactionSummaryResponse],
      in context: NSManagedObjectContext
      ) -> Promise<Set<Int>> {

      return Promise { seal in
        // Construct and persist cache of address index gaps alongside persisting summaries
        var usedReceiveAddressIndices: Set<Int> = []

        responses.forEach { response in
          let ats = CKMAddressTransactionSummary.findOrCreate(with: response, in: context)

          if let pathResponse = response.derivativePathResponse, ats.isChangeAddress != pathResponse.isChangeAddress {
            ats.isChangeAddress = pathResponse.isChangeAddress
          }

          if !ats.isChangeAddress, let index = ats.address?.derivativePath?.index { // only insert receive addresses
            usedReceiveAddressIndices.insert(index)
          }
        }

        // Look for index gaps up to the server address max index to handle edge cases
        let maxServerIndex = CKMServerAddress.maxIndex(in: context) ?? 0
        let maxUsedIndex = usedReceiveAddressIndices.max() ?? 0
        let maxObservedIndex = max(maxServerIndex, maxUsedIndex)

        let allPotentialIndices = Array(0...maxObservedIndex).asSet()
        let unusedReceiveAddressIndices: Set<Int> = allPotentialIndices.subtracting(usedReceiveAddressIndices)

        seal.fulfill(unusedReceiveAddressIndices)
      }
    }

    func persistTemporaryTransaction(
      from transactionData: CNBTransactionData,
      with outgoingTransactionData: OutgoingTransactionData,
      txid: String,
      invitation: CKMInvitation?,
      in context: NSManagedObjectContext
      ) {

      var outgoingTxDTO = outgoingTransactionData
      outgoingTxDTO.txid = txid
      outgoingTxDTO.feeAmount = Int(transactionData.feeAmount)

      invitation?.setTxid(to: txid)
      invitation?.status = .completed

      func updateOrCreateTxForTempTx() -> CKMTransaction {
        if let existingTransaction = CKMTransaction.find(byTxid: txid, in: context),
          let invitation = invitation,
          invitation.transaction !== existingTransaction {

          let txToRemove = invitation.transaction
          invitation.transaction = existingTransaction
          txToRemove.map { context.delete($0) }
          existingTransaction.phoneNumber = invitation.counterpartyPhoneNumber
          return existingTransaction

        } else if let invitation = invitation, let tx = invitation.transaction {
          tx.configure(with: outgoingTxDTO, in: context)
          tx.phoneNumber = invitation.counterpartyPhoneNumber
          return tx

        } else {
          let transaction = CKMTransaction(insertInto: context)
          transaction.configure(with: outgoingTxDTO, in: context)
          return transaction
        }
      }

      // Identify relevantTx to link vouts to its tempTx
      let relevantTransaction = updateOrCreateTxForTempTx()
      relevantTransaction.configureNewSenderSharedPayload(with: outgoingTxDTO.sharedPayloadDTO, in: context)

      // Currently, this function is only called after broadcastTx()
      relevantTransaction.broadcastedAt = Date()

      let vouts = transactionData.unspentTransactionOutputs.compactMap { CKMVout.find(from: $0, in: context) }

      // Link the vout to the relevant tempTx in case we need to mark the tx as failed and free up these vouts
      relevantTransaction.temporarySentTransaction?.reservedVouts = Set(vouts)

      vouts.forEach { $0.isSpent = true }
    }

    func deleteTransactions(notIn txids: [String], in context: NSManagedObjectContext) {
      let transactionsToRemove = CKMTransaction.findAllToDelete(notIn: txids, in: context)
      transactionsToRemove.forEach { context.delete($0) }
    }

    func getAllInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
      return CKMInvitation.getAllInvitations(in: context)
    }

    func getUnacknowledgedInvitations(in context: NSManagedObjectContext) -> [CKMInvitation] {
      return CKMInvitation.findUnacknowledgedInvitations(in: context)
    }

    func transactionsWithoutDayAveragePrice(in context: NSManagedObjectContext) -> Promise<[CKMTransaction]> {
      let pricePredicate = CKPredicate.Transaction.withoutDayAveragePrice()
      let txidPredicate = CKPredicate.Transaction.withValidTxid()
      let compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [pricePredicate, txidPredicate])

      return Promise { seal in
        let request: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
        request.predicate = compoundPredicate
        let results = try context.fetch(request)
        seal.fulfill(results)
      }
    }

    func serverPoolAddresses(in context: NSManagedObjectContext) -> [CKMServerAddress] {
      let request: NSFetchRequest<CKMServerAddress> = CKMServerAddress.fetchRequest()
      request.sortDescriptors = [NSSortDescriptor(key: #keyPath(CKMServerAddress.derivativePath.index), ascending: true)]
      let results = try? context.fetch(request)
      return results ?? []
    }

    func updateLastReceiveAddressIndex(index: Int, in context: NSManagedObjectContext) {
      context.performAndWait {
        CKMWallet.find(in: context)?.lastReceivedIndex = index
      }
    }

    func updateLastChangeAddressIndex(index: Int, in context: NSManagedObjectContext) {
      context.performAndWait {
        CKMWallet.find(in: context)?.lastChangeIndex = index
      }
    }

    func addressesProvidedForReceivedPendingDropBits(in context: NSManagedObjectContext) -> [String] {
      return CKMInvitation.addressesProvidedForReceivedPendingDropBits(in: context)
    }

    /// CKMWallet stores -1 as the default, non-optional value. This function returns nil if the stored value is negative.
    func lastReceiveIndex(in context: NSManagedObjectContext) -> Int? {
      var value: Int?
      context.performAndWait {
        if let lastIndex = CKMWallet.find(in: context)?.lastReceivedIndex, lastIndex >= 0 {
          value = lastIndex
        }
      }
      return value
    }

    /// CKMWallet stores -1 as the default, non-optional value. This function returns nil if the stored value is negative.
    func lastChangeIndex(in context: NSManagedObjectContext) -> Int? {
      var value: Int?
      context.performAndWait {
        if let lastIndex = CKMWallet.find(in: context)?.lastChangeIndex, lastIndex >= 0 {
          value = lastIndex
        }
      }
      return value
    }
  } // end Database class

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
