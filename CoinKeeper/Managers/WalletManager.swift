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

/**
 Warning: Do not store a reference to the wallet manager outside of the single instance assigned to the AppCoordinator.
 All other classes should keep a delegate (WalletDelegateType) reference to the AppCoordinator to access the single wallet manager.

 This is particularly important if the user deleted their wallet and created a new wallet,
 in which case the old wallet manager would still be in memory for any class keeping a reference to it.
 */
class WalletManager: WalletManagerType {

  private(set) var wallet: CNBCnlibHDWallet
  private let persistenceManager: PersistenceManagerType

  let coin: CNBCnlibBaseCoin

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
      return Promise(error: DBTError.Persistence.missingValue(key: "addressPubKeyData"))
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
      var err: NSError?
      words = CNBCnlibNewWordListFromEntropy(entropy, &err).split(separator: " ").map(String.init)
      if let err = err {
        log.error(err, message: "Failed to generate words from entropy.")
      }
    }
    return words
  }

  func validateBase58Check(for address: String) -> Bool {
    var errorPtr: NSError?
    return CNBCnlibAddressIsBase58CheckEncoded(address, &errorPtr)
  }

  func validateBech32Encoding(for address: String) -> Bool {
    var errorPtr: NSError?
    return CNBCnlibAddressIsValidSegwitAddress(address, &errorPtr)
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
    var err: NSError?
    err = nil
    let key = wallet.coinNinjaVerificationKeyHexString(&err)
    if let error = err {
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
    var err: NSError?
    err = nil
    let data = wallet.signatureSigning(data, error: &err)

    if let error = err {
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

  func transactionDataSendingMax(fromPrivateKey privateKey: WIFPrivateKey,
                                 to address: String,
                                 feeRate: Double) -> Promise<CNBCnlibTransactionData> {

    return Promise { seal in
      guard let info = privateKey.key.previousOutputInfo else {
        seal.reject(DBTError.TransactionData.insufficientFunds)
        return
      }

      let blockHeight = persistenceManager.brokers.checkIn.cachedBlockHeight
      let usableFeeRate = self.usableFeeRate(from: feeRate)

      let txData = CNBCnlibNewTransactionDataSendingMax(address, coin, usableFeeRate, blockHeight)
      let utxo = CNBCnlibNewUTXO(info.txid, info.index, info.amount, nil, privateKey.key, privateKey.isConfirmed)
      txData?.add(utxo)

      do {
        try txData?.generate()
        if let data = txData?.transactionData {
          seal.fulfill(data)
        } else {
          seal.reject(DBTError.TransactionData.insufficientFunds)
        }
      } catch {
        seal.reject(error)
      }
    }
  }

  func transactionData(forPayment payment: NSDecimalNumber,
                       to address: String,
                       withFeeRate feeRate: Double,  // in Satoshis
                       rbfOption: RBFOption) -> Promise<CNBCnlibTransactionData> {

    return Promise { seal in
      let paymentAmount = payment.asFractionalUnits(of: .BTC)
      let usableFeeRate = self.usableFeeRate(from: feeRate)
      let blockHeight = persistenceManager.brokers.checkIn.cachedBlockHeight
      let context = persistenceManager.createBackgroundContext()

      context.perform { [weak self] in
        guard let strongSelf = self else {
          seal.reject(DBTError.System.missingValue(key: "wallet manager self"))
          return
        }
        let usableVouts = strongSelf.usableVouts(in: context)
        let allAvailableOutputs = strongSelf.availableTransactionOutputs(fromUsableUTXOs: usableVouts)
        var change: CNBCnlibDerivationPath?

        do {
          change = try strongSelf.newChangePath(in: context)
        } catch {
          log.error(error, message: "Failed to create change path")
          seal.reject(error)
        }

        let data = CNBCnlibNewTransactionDataStandard(address,
                                                      strongSelf.coin,
                                                      paymentAmount,
                                                      usableFeeRate,
                                                      change,
                                                      blockHeight,
                                                      rbfOption.value)

        allAvailableOutputs.forEach { data?.add($0) }

        do {
          try data?.generate()
          if let txData = data?.transactionData {
            seal.fulfill(txData)
          } else {
            seal.reject(DBTError.TransactionData.createTransactionFailure)
          }
        } catch {
          if let txError = DBTError.TransactionData(rawValue: error.localizedDescription) {
            seal.reject(txError)
          } else {
            seal.reject(error)
          }
        }
      }
    }
  }

  func transactionData(forPayment payment: NSDecimalNumber,
                       to address: String,
                       withFeeRate feeRate: Double) -> Promise<CNBCnlibTransactionData> {
    let allowed = RBFOption.allowed
    return transactionData(forPayment: payment, to: address, withFeeRate: feeRate, rbfOption: allowed)
  }

  func transactionData(forPayment payment: Int,
                       to address: String,
                       withFlatFee flatFee: Int) -> Promise<CNBCnlibTransactionData> {

    return Promise { seal in
      guard flatFee > 0 else {
        log.error("flatFee was zero. payment: %d, to address: %@", privateArgs: [payment, address])
        seal.reject(DBTError.TransactionData.insufficientFee)
        return
      }
      let context = persistenceManager.createBackgroundContext()
      context.perform { [weak self] in
        guard let strongSelf = self else {
          seal.reject(DBTError.System.missingValue(key: "wallet manager self"))
          return
        }
        let usableVouts = strongSelf.usableVouts(in: context)
        let allAvailableOutputs = strongSelf.availableTransactionOutputs(fromUsableUTXOs: usableVouts)
        let blockHeight = strongSelf.persistenceManager.brokers.checkIn.cachedBlockHeight
        var change: CNBCnlibDerivationPath?
        do {
          change = try strongSelf.newChangePath(in: context)
        } catch {
          log.error(error, message: "Failed to create change path")
          return
        }

        let data = CNBCnlibTransactionDataFlatFee(address,
                                                  basecoin: strongSelf.coin,
                                                  amount: payment,
                                                  flatFee: flatFee,
                                                  change: change,
                                                  blockHeight: blockHeight)
        allAvailableOutputs.forEach { data?.add($0) }

        do {
          try data?.generate()
          if let data = data?.transactionData {
            seal.fulfill(data)
          } else {
            seal.reject(DBTError.TransactionData.createTransactionFailure)
          }
        } catch {
          if let txError = DBTError.TransactionData(rawValue: error.localizedDescription) {
            seal.reject(txError)
          } else {
            seal.reject(error)
          }
        }
      }
    }
  }

  func transactionDataSendingMax(to address: String, withFeeRate feeRate: Double) -> Promise<CNBCnlibTransactionData> {
    return Promise { seal in
      let usableFeeRate = self.usableFeeRate(from: feeRate)
      let blockHeight = persistenceManager.brokers.checkIn.cachedBlockHeight
      let context = persistenceManager.createBackgroundContext()

      context.perform { [weak self] in
        guard let strongSelf = self else {
          seal.reject(DBTError.System.missingValue(key: "wallet manager self"))
          return
        }
        let usableVouts = strongSelf.usableVouts(in: context)
        let allAvailableOutputs = strongSelf.availableTransactionOutputs(fromUsableUTXOs: usableVouts)

        // This initializer uses RBFOption MustNotBeRBF.
        let data = CNBCnlibNewTransactionDataSendingMax(address, strongSelf.coin, usableFeeRate, blockHeight)
        allAvailableOutputs.forEach { data?.add($0) }

        do {
          try data?.generate()
          if let txData = data?.transactionData {
            seal.fulfill(txData)
          } else {
            seal.reject(DBTError.TransactionData.createTransactionFailure)
          }
        } catch {
          log.error(error, message: "Failed to generate send max transaction")
          if let txError = DBTError.TransactionData(rawValue: error.localizedDescription) {
            seal.reject(txError)
          } else {
            seal.reject(error)
          }
        }
      }
    }
  }

  func transactionDataSendingAll(to address: String, withFeeRate feeRate: Double) -> Promise<CNBCnlibTransactionData> {
    return Promise { seal in
      let context = persistenceManager.viewContext
      let unspent = CKMVout.unspentBalance(in: context)
      guard unspent > 0 else {
        seal.reject(DBTError.TransactionData.noSpendableFunds)
        return
      }

      let usableFeeRate = self.usableFeeRate(from: feeRate)
      let blockHeight = persistenceManager.brokers.checkIn.cachedBlockHeight

      context.perform { [weak self] in
        guard let strongSelf = self else {
          seal.reject(DBTError.System.missingValue(key: "wallet manager self"))
          return
        }
        do {
          let vouts = try CKMVout.findAllUnspent(in: context)
          let utxos = strongSelf.availableTransactionOutputs(fromUsableUTXOs: vouts)
          let data = CNBCnlibNewTransactionDataSendingMax(address, strongSelf.coin, usableFeeRate, blockHeight)

          utxos.forEach { data?.add($0) }

          try data?.generate()

          if let txData = data?.transactionData {
            seal.fulfill(txData)
          } else {
            seal.reject(DBTError.TransactionData.createTransactionFailure)
          }
        } catch {
          log.error(error, message: "Failed to generate send all transaction")
          if let txError = DBTError.TransactionData(rawValue: error.localizedDescription) {
            seal.reject(txError)
          } else {
            seal.reject(error)
          }
        }
      }
    }
  }

  func decodeLightningInvoice(_ invoice: String) -> Promise<LNDecodePaymentRequestResponse> {
    do {
      let decoded = try wallet.decodeLightningInvoice(invoice)
      let response = LNDecodePaymentRequestResponse(
        numSatoshis: decoded.numSatoshis,
        description: decoded.description.asNilIfEmpty()
      )
      return .value(response)
    } catch {
      return Promise(error: error)
    }
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
    let defaultPath = CNBCnlibNewDerivationPath(coin, 1, 0)!
    return try self.createAddressDataSource().nextChangeAddress(in: context).derivationPath ?? defaultPath
  }
}
