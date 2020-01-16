//
//  WalletManagerType.swift
//  DropBit
//
//  Created by Ben Winters on 1/16/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import Cnlib
import PromiseKit

protocol WalletManagerType: AnyObject {
  static func createMnemonicWords() -> [String]
  static func secureEntropy() -> Data
  func validateBase58Check(for address: String) -> Bool
  func validateBech32Encoding(for address: String) -> Bool
  var coin: CNBCnlibBaseCoin { get }
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
                       rbfOption: RBFOption) -> Promise<CNBCnlibTransactionData>

  /// Returns nil instead of an error in the case of insufficient funds, uses default `rbfOption: .Allowed`
  func failableTransactionData(forPayment payment: NSDecimalNumber,
                               to address: String,
                               withFeeRate feeRate: Double) -> CNBCnlibTransactionData?

  func failableTransactionData(forPayment payment: NSDecimalNumber,
                               to address: String,
                               withFeeRate feeRate: Double,
                               rbfOption: RBFOption) -> CNBCnlibTransactionData?

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

  func decodeLightningInvoice(_ invoiceString: String) -> Promise<LNDecodePaymentRequestResponse>
}
