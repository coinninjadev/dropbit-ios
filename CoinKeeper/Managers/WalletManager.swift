//
//  WalletManager.swift
//  DropBit
//
//  Created by BJ Miller on 3/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import PromiseKit
import Cnlib

protocol WalletManagerType: AnyObject {
  static func createMnemonicWords() -> [String]
  static func secureEntropy() -> Data
  func validateBase58Check(for address: String) -> Bool
  func validateBech32Encoding(for address: String) -> Bool
  var coin: CNBCnlibBasecoin { get }
  var wallet: CNBCnlibHDWallet { get }
  func hexEncodedPublicKey() throws -> String
  func hexEncodedPublicKeyPromise() -> Promise<String>
  func signatureSigning(data: Data) throws -> String
  func signatureSigningPromise(data: Data) -> Promise<String>
  func usableFeeRate(from feeRate: Double) -> Int
  func mnemonicWords() -> [String]
  func resetWallet(with words: [String])

  func createAddressDataSource() -> AddressDataSourceType

  /// Use this when displaying the balance
  func balanceNetPending(in context: NSManagedObjectContext) -> (onChain: Int, lightning: Int)

  /// Spendable UTXOs
  /// number of confirmations affects isSpendable, returns a min of 0
  func spendableBalance(in context: NSManagedObjectContext) -> (onChain: Int, lightning: Int)

  func activeTemporarySentTxTotal(forType walletTxType: WalletTransactionType,
                                  in context: NSManagedObjectContext) -> Int

  func transactionData(forPayment payment: NSDecimalNumber,
                       to address: String,
                       withFeeRate feeRate: Double,
                       rbfOption: CNBCnlibRBFOption) -> Promise<CNBCnlibTransactionData>

  /// Returns nil instead of an error in the case of insufficient funds, uses default `rbfOption: .Allowed`
  func failableTransactionData(forPayment payment: NSDecimalNumber,
                               to address: String,
                               withFeeRate feeRate: Double) -> CNBCnlibTransactionData?

  func failableTransactionData(forPayment payment: NSDecimalNumber,
                               to address: String,
                               withFeeRate feeRate: Double,
                               rbfOption: CNBCnlibRBFOption) -> CNBCnlibTransactionData?

  /// Transaction data for payment to a recipient with a flat, predetermined fee.
  ///
  /// - Parameters:
  ///   - payment: Amount (in satoshis) to pay.
  ///   - address: Destination payment address.
  ///   - flatFee: Predetermined fee (NOT a rate) for the transaction
  /// - Returns: A Promise that either contains a CNBCnlibTransactionData object, or rejects if insufficient funds.
  func transactionData(
    forPayment payment: Int,
    to address: String,
    withFlatFee flatFee: Int
    ) -> Promise<CNBCnlibTransactionData>

  /// Transaction data for sending max wallet amount, minus fee, to a given address.
  ///
  /// - Parameters:
  ///   - address: Destination payment address.
  ///   - feeRate: Fee rate per bytes, in Satoshis
  /// - Returns: A Promise that either contains a CNBCnlibTransactionData object, ro rejects if insufficient funds.
  func transactionDataSendingMax(to address: String, withFeeRate feeRate: Double) -> Promise<CNBCnlibTransactionData>

  /// Returns nil instead of an error in the case of insufficient funds
  func failableTransactionDataSendingMax(to address: String, withFeeRate feeRate: Double) -> CNBCnlibTransactionData?

  /// Returns nil instead of an error in the case of insufficient funds. Takes all unspent outputs, ignoring dust protection and confirmation count.
  func failableTransactionDataSendingAll(to address: String, withFeeRate feeRate: Double) -> CNBCnlibTransactionData?
  func transactionDataSendingAll(to address: String, withFeeRate feeRate: Double) -> Promise<CNBCnlibTransactionData>

  func encryptPayload<T>(_ payload: T, addressPubKey: String, keyIsEphemeral: Bool) -> Promise<String> where T: SharedPayloadCodable
//  func decryptPayload<T>(_ payload: String, path: CNBCnlibDerivationPath) -> Promise<T> where T: SharedPayloadCodable
}

/**
 Warning: Do not store a reference to the wallet manager outside of the single instance assigned to the AppCoordinator.
 All other classes should keep a delegate (WalletDelegateType) reference to the AppCoordinator to access the single wallet manager.

 This is particularly important if the user deleted their wallet and created a new wallet,
 in which case the old wallet manager would still be in memory for any class keeping a reference to it.
 */
class WalletManager: WalletManagerType {

  private(set) var wallet: CNBCnlibHDWallet
  private let persistenceManager: PersistenceManagerType

  let coin: CNBCnlibBasecoin

  init?(words: [String], persistenceManager: PersistenceManagerType = PersistenceManager()) {
    let relevantCoin = persistenceManager.usableCoin
    let joinedWords = words.joined(separator: " ")
    if let wallet = CNBCnlibNewHDWalletFromWords(joinedWords, relevantCoin) {
      self.wallet = wallet
    } else {
      return nil
    }
    self.coin = relevantCoin
    self.persistenceManager = persistenceManager
  }

  func encryptPayload<T>(_ payload: T, addressPubKey: String, keyIsEphemeral: Bool) -> Promise<String> where T: SharedPayloadCodable {
    guard let addressPubKeyData = Data(fromHexEncodedString: addressPubKey) else {
      return Promise(error: CKPersistenceError.missingValue(key: "addressPubKeyData"))
    }

    return Promise { seal in
      do {
        let encodedPayload = try payload.encoded()
        let cryptor = CKCryptor(walletManager: self)
        let encryptedPayloadString = try cryptor.encryptAsBase64String(message: encodedPayload,
                                                                       withRecipientUncompressedPubkey: addressPubKeyData,
                                                                       isEphemeral: keyIsEphemeral)
        seal.fulfill(encryptedPayloadString)
      } catch {
        seal.reject(error)
      }
    }
  }

  static func secureEntropy() -> Data {
    let len = 16; // 16 bytes
    var data = Data(count: len)

    let result = data.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, len, $0.baseAddress!) }

    guard result == errSecSuccess else { return Data() }

    return data
  }

  public static func createMnemonicWords() -> [String] {
    var words: [String] = []
    while words.count != 12 {
      let entropy = secureEntropy()
      let err = NSErrorPointer(nilLiteral: ())
      words = CNBCnlibNewWordListFromEntropy(entropy, err).split(separator: " ").map(String.init)
    }
    return words
  }

  func validateBase58Check(for address: String) -> Bool {
    let errorPtr = NSErrorPointer(nilLiteral: ())
    return CNBCnlibAddressIsBase58CheckEncoded(address, nil, errorPtr)
  }

  func validateBech32Encoding(for address: String) -> Bool {
    let errorPtr = NSErrorPointer(nilLiteral: ())
    return CNBCnlibAddressIsValidSegwitAddress(address, nil, errorPtr)
  }

  var minimumFeeRate: Int {
    return 1
  }

  func createAddressDataSource() -> AddressDataSourceType {
    return AddressDataSource(wallet: wallet, persistenceManager: persistenceManager)
  }

  func activeTemporarySentTxTotal(forType walletTxType: WalletTransactionType,
                                  in context: NSManagedObjectContext) -> Int {
    let tempTransactions: [CKMTemporarySentTransaction]
    switch walletTxType {
    case .onChain:    tempTransactions = CKMTemporarySentTransaction.findAllActiveOnChain(in: context)
    case .lightning:  tempTransactions = CKMTemporarySentTransaction.findAllActiveLightning(in: context)
    }

    //use totalAmount for both walletTxTypes since we cover fees for lightning load transactions
    let total = tempTransactions.reduce(0) { $0 + $1.totalAmount }
    return total
  }

  func balanceNetPending(in context: NSManagedObjectContext) -> (onChain: Int, lightning: Int) {
    let wallet = CKMWallet.findOrCreate(in: context)
    let atss = CKMAddressTransactionSummary.findAll(matching: coin, in: context)
    let atsAmount = atss.reduce(0) { $0 + $1.netAmount }
    let tempSentTxTotal = activeTemporarySentTxTotal(forType: .onChain, in: context)
    let netOnChainBalance = atsAmount - tempSentTxTotal

    let lightningAccount = persistenceManager.brokers.lightning.getAccount(forWallet: wallet, in: context)
    let tempSentLightningTotal = activeTemporarySentTxTotal(forType: .lightning, in: context)
    let netLightningBalance = lightningAccount.balance + lightningAccount.pendingIn + tempSentLightningTotal
    return (onChain: netOnChainBalance, lightning: netLightningBalance)
  }

  func spendableBalance(in context: NSManagedObjectContext) -> (onChain: Int, lightning: Int) {
    guard let wallet = CKMWallet.find(in: context) else { return (0, 0) }
    let minAmount = self.persistenceManager.brokers.preferences.dustProtectionMinimumAmount
    let lightningAccount = self.persistenceManager.brokers.lightning.getAccount(forWallet: wallet, in: context)
    let spendableVouts = CKMVout.findAllSpendable(minAmount: minAmount, in: context)
    let spendableTotal = spendableVouts.reduce(0) { $0 + $1.amount }

    return (onChain: spendableTotal, lightning: lightningAccount.balance)
  }

  func hexEncodedPublicKey() throws -> String {
    let err = NSErrorPointer(nilLiteral: ())
    let key = wallet.coinNinjaVerificationKeyHexString(err)
    if let error = err?.pointee {
      log.error(error, message: "Failed to get hex encoded public key for wallet.")
      throw error
    }
    return key
  }

  func hexEncodedPublicKeyPromise() -> Promise<String> {
    return Promise<String> { seal in
      do {
        let pubkey = try self.hexEncodedPublicKey()
        seal.fulfill(pubkey)
      } catch {
        seal.reject(error)
      }
    }
  }

  func resetWallet(with words: [String]) {
    CNBCnlibHDWallet(fromWords: words.joined(separator: " "), basecoin: coin).map { self.wallet = $0 }
  }

  func mnemonicWords() -> [String] {
    return wallet.walletWords.split(separator: " ").map(String.init)
  }

  func signatureSigning(data: Data) throws -> String {
    let errorPointer = NSErrorPointer(nilLiteral: ())
    let data = wallet.signatureSigning(data, error: errorPointer)

    if let error = errorPointer?.pointee {
      log.error(error, message: "Failed to sign data with signature.")
      throw error
    }

    return data
  }

  func signatureSigningPromise(data: Data) -> Promise<String> {
    return Promise { seal in
      do {
        let signature = try signatureSigning(data: data)
        seal.fulfill(signature)
      } catch {
        seal.reject(error)
      }
    }
  }

  func usableFeeRate(from feeRate: Double) -> Int {
    let floored = floor(feeRate)
    return max(Int(exactly: floored) ?? 0, minimumFeeRate)
  }

  func transactionData(
    forPayment payment: NSDecimalNumber,
    to address: String,
    withFeeRate feeRate: Double,  // in Satoshis
    rbfOption: CNBCnlibRBFOption
    ) -> Promise<CNBCnlibTransactionData> {

    return Promise { seal in
      let txData = failableTransactionData(forPayment: payment,
                                           to: address,
                                           withFeeRate: feeRate,
                                           rbfOption: rbfOption)
      if let data = txData {
        seal.fulfill(data)
      } else {
        seal.reject(TransactionDataError.insufficientFunds)
      }
    }
  }

  func failableTransactionData(forPayment payment: NSDecimalNumber,
                               to address: String,
                               withFeeRate feeRate: Double) -> CNBCnlibTransactionData? {
    let allowed = CNBCnlibRBFOption(CNBCnlibAllowedToBeRBF)!
    return failableTransactionData(forPayment: payment, to: address, withFeeRate: feeRate, rbfOption: allowed)
  }

  func failableTransactionData(
    forPayment payment: NSDecimalNumber,
    to address: String,
    withFeeRate feeRate: Double,
    rbfOption: CNBCnlibRBFOption) -> CNBCnlibTransactionData? {
    let paymentAmount = payment.asFractionalUnits(of: .BTC)
    let usableFeeRate = self.usableFeeRate(from: feeRate)
    let blockHeight = persistenceManager.brokers.checkIn.cachedBlockHeight
    let bgContext = persistenceManager.createBackgroundContext()
    var result: CNBCnlibTransactionData?
    bgContext.performAndWait {
      let usableVouts = self.usableVouts(in: bgContext)
      let allAvailableOutputs = self.availableTransactionOutputs(fromUsableUTXOs: usableVouts)
      var change: CNBCnlibDerivationPath?
      do {
        change = try self.newChangePath(in: bgContext)
      } catch {
        log.error(error, message: "Failed to create change path")
        return
      }

      let data = CNBCnlibTransactionDataStandard(address,
                                                 basecoin: coin,
                                                 amount: paymentAmount,
                                                 feeRate: usableFeeRate,
                                                 change: change,
                                                 blockHeight: blockHeight,
                                                 rbfOption: rbfOption)

      for utxo in allAvailableOutputs {
        data?.add(utxo)
      }

      do {
        var boolPtr: UnsafeMutablePointer<ObjCBool>?
        try data?.generate(boolPtr)

        if let bool = boolPtr?.pointee, bool.boolValue == false {
          log.error("Failed to generate transaction data: insufficient funds.")
        }

        result = data?.transactionData
      } catch {
        log.error(error, message: "Failed to generate standard transaction data.")
        return
      }

    }
    return result
  }

  func transactionData(
    forPayment payment: Int,
    to address: String,
    withFlatFee flatFee: Int
    ) -> Promise<CNBCnlibTransactionData> {

    return Promise { seal in
      guard flatFee > 0 else {
        log.error("flatFee was zero. payment: %d, to address: %@", privateArgs: [payment, address])
        seal.reject(TransactionDataError.insufficientFee)
        return
      }
      let bgContext = persistenceManager.createBackgroundContext()
      bgContext.perform { [weak self] in
        guard let strongSelf = self else {
          seal.reject(CKSystemError.missingValue(key: "wallet manager self"))
          return
        }
        let usableVouts = strongSelf.usableVouts(in: bgContext)
        let allAvailableOutputs = strongSelf.availableTransactionOutputs(fromUsableUTXOs: usableVouts)
        let blockHeight = strongSelf.persistenceManager.brokers.checkIn.cachedBlockHeight
        var change: CNBCnlibDerivationPath?
        do {
          change = try strongSelf.newChangePath(in: bgContext)
        } catch {
          log.error(error, message: "Failed to create change path")
          return
        }

        let txData = CNBCnlibTransactionDataFlatFee(address,
                                                    basecoin: strongSelf.coin,
                                                    amount: payment,
                                                    flatFee: flatFee,
                                                    change: change,
                                                    blockHeight: blockHeight)
        for utxo in allAvailableOutputs {
          txData?.add(utxo)
        }

        do {
          try txData?.generate(nil)
          if let data = txData?.transactionData {
            seal.fulfill(data)
          } else {
            seal.reject(TransactionDataError.insufficientFunds)
          }
        } catch {
          seal.reject(error)
        }
      }
    }
  }

  func transactionDataSendingMax(to address: String, withFeeRate feeRate: Double) -> Promise<CNBCnlibTransactionData> {
    return Promise { seal in
      let maybeTxData = self.failableTransactionDataSendingMax(to: address, withFeeRate: feeRate)
      if let data = maybeTxData {
        seal.fulfill(data)
      } else {
        seal.reject(TransactionDataError.insufficientFunds)
      }
    }
  }

  func failableTransactionDataSendingMax(to address: String, withFeeRate feeRate: Double) -> CNBCnlibTransactionData? {
    let usableFeeRate = self.usableFeeRate(from: feeRate)
    let blockHeight = persistenceManager.brokers.checkIn.cachedBlockHeight
    let bgContext = persistenceManager.createBackgroundContext()

    var result: CNBCnlibTransactionData?
    bgContext.performAndWait {
      let usableVouts = self.usableVouts(in: bgContext)
      let allAvailableOutputs = self.availableTransactionOutputs(fromUsableUTXOs: usableVouts)

      ///This initializer uses CNBTransactionReplaceabilityOption.MustNotBeRBF
      let data = CNBCnlibNewTransactionDataSendingMax(address, coin, usableFeeRate, blockHeight)
      for utxo in allAvailableOutputs {
        data?.add(utxo)
      }

      do {
        try data?.generate(nil)
        result = data?.transactionData
      } catch {
        log.error(error, message: "Failed to generate send max transaction")
      }
    }
    return result
  }

  func transactionDataSendingAll(to address: String, withFeeRate feeRate: Double) -> Promise<CNBCnlibTransactionData> {
    return Promise { seal in
      let context = persistenceManager.viewContext
      let unspent = CKMVout.unspentBalance(in: context)
      guard unspent > 0 else {
        seal.reject(TransactionDataError.noSpendableFunds)
        return
      }

      let maybeTxData = self.failableTransactionDataSendingAll(to: address, withFeeRate: feeRate)
      if let data = maybeTxData {
        seal.fulfill(data)
      } else {
        seal.reject(TransactionDataError.insufficientFunds)
      }
    }
  }

  func failableTransactionDataSendingAll(to address: String, withFeeRate feeRate: Double) -> CNBCnlibTransactionData? {
    let usableFeeRate = self.usableFeeRate(from: feeRate)
    let blockHeight = persistenceManager.brokers.checkIn.cachedBlockHeight
    let context = persistenceManager.viewContext

    var result: CNBCnlibTransactionData?
    context.performAndWait {
      do {
        let vouts = try CKMVout.findAllUnspent(in: context)
        let utxos = self.availableTransactionOutputs(fromUsableUTXOs: vouts)
        let data = CNBCnlibNewTransactionDataSendingMax(address, coin, usableFeeRate, blockHeight)
        for utxo in utxos {
          data?.add(utxo)
        }
        try data?.generate(nil)
        result = data?.transactionData
      } catch {
        log.error(error, message: "Failed to generate send all transaction")
      }
    }
    return result
  }

  /// - parameter limitByPending: true to remove the smallest vouts, to not exceed spendableBalanceNetPending()
  private func usableVouts(in context: NSManagedObjectContext) -> [CKMVout] {
    let dustProtectionAmount = self.persistenceManager.brokers.preferences.dustProtectionMinimumAmount
    return CKMVout.findAllSpendable(minAmount: dustProtectionAmount, in: context)
  }

  private func availableTransactionOutputs(fromUsableUTXOs usableUTXOs: [CKMVout]) -> [CNBCnlibUTXO] {
    return usableUTXOs.compactMap { (vout: CKMVout) -> CNBCnlibUTXO? in
      guard let transaction = vout.transaction,
        let derivationPath = vout.address?.derivativePath
        else { return nil }

      let path = derivationPath.asCNBDerivationPath()
      let output = CNBCnlibUTXO(transaction.txid,
                                index: vout.index,
                                amount: vout.amount,
                                path: path,
                                importedPrivateKey: nil,
                                isConfirmed: transaction.isConfirmed)
      return output
    }
  }

  private func newChangePath(in context: NSManagedObjectContext) throws -> CNBCnlibDerivationPath {
    let defaultPath = CNBCnlibDerivationPath(coin.purpose, coin: coin.coin, account: coin.account, change: 1, index: 0)!
    return try self.createAddressDataSource().nextChangeAddress(in: context).derivationPath ?? defaultPath
  }

}
