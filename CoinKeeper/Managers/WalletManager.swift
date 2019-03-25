//
//  WalletManager.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit
import CoreData
import PromiseKit
import os.log

protocol WalletManagerType: AnyObject {
  static func createMnemonicWords() -> [String]
  static func validateBase58Check(for address: String) -> Bool
  var coin: CNBBaseCoin { get set }
  var wallet: CNBHDWallet { get }
  var hexEncodedPublicKey: String { get }
  func signatureSigning(data: Data) -> String
  func mnemonicWords() -> [String]
  func resetWallet(with words: [String])

  func createAddressDataSource() -> AddressDataSourceType

  /// Create copy of current CNBHDWallet object for multi-broadcast necessity (avoiding crash)
  func createWalletCopy() -> CNBHDWallet

  /// Use this when displaying the balance
  func balanceNetPending(in context: NSManagedObjectContext) -> Int

  /// Spendable UTXOs
  /// number of confirmations affects isSpendable, returns a min of 0
  func spendableBalance(in context: NSManagedObjectContext) -> Int

  /// Spendable UTXOs --minus pending or temporary transactions--,
  /// number of confirmations affects isSpendable, returns a min of 0
  func spendableBalanceNetPending(in context: NSManagedObjectContext) -> Int

  func activeTemporarySentTxTotal(in context: NSManagedObjectContext) -> Int

  func transactionData(
    forPayment payment: NSDecimalNumber,
    to address: String,
    withFeeRate feeRate: Double
    ) -> Promise<CNBTransactionData>

  /// Transaction data for payment to a recipient with a flat, predetermined fee.
  ///
  /// - Parameters:
  ///   - payment: Amount (in satoshis) to pay.
  ///   - address: Destination payment address.
  ///   - flatFee: Predetermined fee (NOT a rate) for the transaction
  /// - Returns: A Promise that either contains a CNBTransactionData object, or rejects if insufficient funds.
  func transactionData(
    forPayment payment: Int,
    to address: String,
    withFlatFee flatFee: Int
    ) -> Promise<CNBTransactionData>

  /// Transaction data for sending max wallet amount, minus fee, to a given address.
  ///
  /// - Parameters:
  ///   - address: Destination payment address.
  ///   - feeRate: Fee rate per bytes, in Satoshis
  /// - Returns: A Promise that either contains a CNBTransactionData object, ro rejects if insufficient funds.
  func transactionDataSendingMax(to address: String, withFeeRate feeRate: Double) -> Promise<CNBTransactionData>

  func encryptionCipherKeys(forUncompressedPublicKey pubkey: Data) -> CNBEncryptionCipherKeys
  func decryptionCipherKeys(
    forReceiveAddressPath path: CKMDerivativePath,
    withPublicKey pubkey: Data,
    in context: NSManagedObjectContext
    ) -> CNBCipherKeys

  func encryptPayload<T>(_ payload: T, addressPubKey: String) -> Promise<String> where T: SharedPayloadCodable
}

/**
 Warning: Do not store a reference to the wallet manager outside of the single instance assigned to the AppCoordinator.
 All other classes should keep a delegate (WalletDelegateType) reference to the AppCoordinator to access the single wallet manager.

 This is particularly important if the user deleted their wallet and created a new wallet,
 in which case the old wallet manager would still be in memory for any class keeping a reference to it.
 */
class WalletManager: WalletManagerType {

  func encryptionCipherKeys(forUncompressedPublicKey pubkey: Data) -> CNBEncryptionCipherKeys {
    return wallet.encryptionCipherKeys(forPublicKey: pubkey)
  }

  func decryptionCipherKeys(
    forReceiveAddressPath path: CKMDerivativePath,
    withPublicKey pubkey: Data,
    in context: NSManagedObjectContext
    ) -> CNBCipherKeys {
    let cnbPath = path.asCNBDerivationPath()
    return wallet.decryptionCipherKeysForDerivationPath(ofPrivateKey: cnbPath, publicKey: pubkey)
  }

  func encryptPayload<T>(_ payload: T, addressPubKey: String) -> Promise<String> where T: SharedPayloadCodable {
    guard let addressPubKeyData = Data(fromHexEncodedString: addressPubKey) else {
      return Promise(error: CKPersistenceError.missingValue(key: "addressPubKeyData"))
    }

    return Promise { seal in
      do {
        let encodedPayload = try payload.encoded()
        let cryptor = CKCryptor(walletManager: self)
        let encryptedPayloadString = try cryptor.encryptAsBase64String(message: encodedPayload, withRecipientUncompressedPubkey: addressPubKeyData)
        seal.fulfill(encryptedPayloadString)
      } catch {
        seal.reject(error)
      }
    }
  }

  public static func createMnemonicWords() -> [String] {
    return CNBHDWallet.createMnemonicWords()
  }

  static func validateBase58Check(for address: String) -> Bool {
    return CNBHDWallet.addressIsBase58CheckEncoded(address)
  }

  private(set) var wallet: CNBHDWallet
  private let persistenceManager: PersistenceManagerType

  var minimumFeeRate: UInt {
    return 5
  }

  private let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "wallet_manager")

  func createAddressDataSource() -> AddressDataSourceType {
    return AddressDataSource(wallet: self.wallet, persistenceManager: self.persistenceManager)
  }

  func activeTemporarySentTxTotal(in context: NSManagedObjectContext) -> Int {
    let tempTransactions = CKMTemporarySentTransaction.findAllActive(in: context)
    let total = tempTransactions.reduce(0) { $0 + $1.totalAmount }
    return total
  }

  func balanceNetPending(in context: NSManagedObjectContext) -> Int {
    var netBalance = 0
    context.performAndWait {
      let atss = CKMAddressTransactionSummary.findAll(in: context)
      let atsAmount = atss.reduce(0) { $0 + $1.netAmount }
      let tempSentTxTotal = activeTemporarySentTxTotal(in: context)
      netBalance = atsAmount - tempSentTxTotal
    }
    return netBalance
  }

  func spendableBalance(in context: NSManagedObjectContext) -> Int {
    var spendable = 0
    context.performAndWait {
      spendable = spendableBalance(netPending: false, in: context)
    }
    return spendable
  }

  func spendableBalanceNetPending(in context: NSManagedObjectContext) -> Int {
    var spendable = 0
    context.performAndWait {
      spendable = spendableBalance(netPending: true, in: context)
    }
    return spendable
  }

  private func spendableBalance(netPending: Bool, in context: NSManagedObjectContext) -> Int {
    let spendableVouts = CKMVout.findAllSpendable(in: context)
    let spendableTotal = spendableVouts.reduce(0) { $0 + $1.amount }

    var balance: Int = spendableTotal
    if netPending {
      let tempTxTotal = self.activeTemporarySentTxTotal(in: context)
      balance -= tempTxTotal
    }

    // Vouts are marked as not spendable for more than the transaction amount until change is received,
    // so netPending calculation may be negative during this time.
    return max(0, balance)
  }

  init(words: [String], coin: CNBBaseCoin = BTCMainnetCoin(), persistenceManager: PersistenceManagerType = PersistenceManager()) {
    self.wallet = CNBHDWallet(mnemonic: words, coin: coin)
    self.coin = coin
    self.persistenceManager = persistenceManager
  }

  /// Setting coin will update wallet object with new coin.
  var coin: CNBBaseCoin {
    didSet {
      wallet.setCoin(coin)
    }
  }

  var hexEncodedPublicKey: String {
    return wallet.coinNinjaVerificationKeyHexString
  }

  func resetWallet(with words: [String]) {
    self.wallet = CNBHDWallet(mnemonic: words, coin: coin)
  }

  func createWalletCopy() -> CNBHDWallet {
    return CNBHDWallet(mnemonic: mnemonicWords(), coin: coin)
  }

  func mnemonicWords() -> [String] {
    return wallet.mnemonicWords().compactMap { $0 as? String }
  }

  func signatureSigning(data: Data) -> String {
    return wallet.signatureSigning(data)
  }

  func usableFeeRate(from feeRate: Double) -> UInt {
    let floored = floor(feeRate)
    return max(UInt(exactly: floored) ?? 0, minimumFeeRate)
  }

  func transactionData(
    forPayment payment: NSDecimalNumber,
    to address: String,
    withFeeRate feeRate: Double  // in Satoshis
    ) -> Promise<CNBTransactionData> {

    return Promise { seal in
      let paymentAmount = UInt(payment.asFractionalUnits(of: .BTC))
      let usableFeeRate = self.usableFeeRate(from: feeRate)
      let blockHeight = UInt(persistenceManager.integer(for: .blockheight))
      let bgContext = persistenceManager.createBackgroundContext()
      bgContext.performAndWait {
        let usableVouts = self.unspentVoutsRelativeToUser(in: bgContext)
        let allAvailableOutputs = self.unspentTransactionOutputs(fromUsableUTXOs: usableVouts)

        let txData = CNBTransactionData(
          address: address,
          fromAllAvailableOutputs: allAvailableOutputs,
          paymentAmount: paymentAmount,
          feeRate: usableFeeRate,
          change: self.newChangePath(in: bgContext),
          blockHeight: blockHeight
        )
        if let data = txData {
          seal.fulfill(data)
        } else {
          seal.reject(TransactionDataError.insufficientFunds)
        }
      }
    }

  }

  func transactionData(
    forPayment payment: Int,
    to address: String,
    withFlatFee flatFee: Int
    ) -> Promise<CNBTransactionData> {

    return Promise { seal in
      guard flatFee > 0 else {
        os_log("flatFee was zero. payment: %d, to address: %@", log: self.logger, type: .debug, payment, address)
        seal.reject(TransactionDataError.insufficientFee)
        return
      }
      let bgContext = persistenceManager.createBackgroundContext()
      bgContext.performAndWait {
        let usableVouts = self.unspentVoutsRelativeToUser(in: bgContext)
        let allAvailableOutputs = self.unspentTransactionOutputs(fromUsableUTXOs: usableVouts)
        let paymentAmount = UInt(payment)
        let feeAmount = UInt(flatFee)
        let blockHeight = UInt(persistenceManager.integer(for: .blockheight))

        let txData = CNBTransactionData(
          address: address,
          fromAllAvailableOutputs: allAvailableOutputs,
          paymentAmount: paymentAmount,
          flatFee: feeAmount,
          change: self.newChangePath(in: bgContext),
          blockHeight: blockHeight
        )
        if let data = txData {
          seal.fulfill(data)
        } else {
          seal.reject(TransactionDataError.insufficientFunds)
        }
      }
    }
  }

  func transactionDataSendingMax(to address: String, withFeeRate feeRate: Double) -> Promise<CNBTransactionData> {
    return Promise { seal in
      let usableFeeRate = self.usableFeeRate(from: feeRate)
      let blockHeight = UInt(persistenceManager.integer(for: .blockheight))
      let bgContext = persistenceManager.createBackgroundContext()
      bgContext.performAndWait {
        let usableVouts = self.unspentVoutsRelativeToUser(in: bgContext)
        let allAvailableOutputs = self.unspentTransactionOutputs(fromUsableUTXOs: usableVouts)

        let txData = CNBTransactionData(
          allUsableOutputs: allAvailableOutputs,
          sendingMaxToAddress: address,
          feeRate: usableFeeRate,
          blockHeight: blockHeight
        )
        if let data = txData {
          seal.fulfill(data)
        } else {
          seal.reject(TransactionDataError.insufficientFunds)
        }
      }
    }
  }

  private func unspentVoutsRelativeToUser(in context: NSManagedObjectContext) -> [CKMVout] {
    let voutFetchRequest: NSFetchRequest<CKMVout> = CKMVout.fetchRequest()
    voutFetchRequest.predicate = CKPredicate.Vout.isSpendable()
    var vouts: [CKMVout] = []
    do {
      vouts = try context.fetch(voutFetchRequest)
    } catch {
      os_log("Failed to fetch utxos: %@", log: self.logger, type: .error, error.localizedDescription)
    }
    return vouts
  }

  private func unspentTransactionOutputs(fromUsableUTXOs usableUTXOs: [CKMVout]) -> [CNBUnspentTransactionOutput] {
    return usableUTXOs.compactMap { (vout: CKMVout) -> CNBUnspentTransactionOutput? in
      guard let txid = vout.transaction?.txid, let derivationPath = vout.address?.derivativePath else { return nil }
      guard let transaction = vout.transaction else { return nil }
      let index = UInt(vout.index)
      let amount = UInt(vout.amount)
      let cnbDerivativePath = CNBDerivationPath(
        purpose: CoinDerivation(rawValue: UInt(derivationPath.purpose)) ?? .BIP49,
        coinType: CoinType(rawValue: UInt(derivationPath.coin)) ?? .MainNet,
        account: UInt(derivationPath.account),
        change: UInt(derivationPath.change),
        index: UInt(derivationPath.index)
      )
      let output = CNBUnspentTransactionOutput(id: txid,
                                               index: index,
                                               amount: amount,
                                               derivationPath: cnbDerivativePath,
                                               isConfirmed: transaction.isConfirmed)
      return output
    }
  }

  private func newChangePath(in context: NSManagedObjectContext) -> CNBDerivationPath {
    let changeAddress = self.createAddressDataSource().nextChangeAddress(in: context)
    return CNBDerivationPath(
      purpose: CoinDerivation(rawValue: changeAddress.derivationPath.purpose.rawValue) ?? .BIP49,
      coinType: CoinType(rawValue: changeAddress.derivationPath.coinType.rawValue) ?? .MainNet,
      account: changeAddress.derivationPath.account,
      change: changeAddress.derivationPath.change,
      index: changeAddress.derivationPath.index
    )
  }

}
