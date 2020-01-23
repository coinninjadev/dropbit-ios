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

  /// Transaction data for payment to a recipient with a flat, predetermined fee.
  ///
  /// - Parameters:
  ///   - payment: Amount (as BTC NSDecimalNumber) to pay.
  ///   - address: Destination payment address.
  ///   - feeRate: Fee rate per bytes, in Satoshis
  ///   - rbfOption: Option to give to transaction such as Allowed, MustBeRBF, or MustNotBeRBF.
  /// - Returns: A Promise that contains a CNBCnlibTransactionData object, or rejects if failed.
  func transactionData(forPayment payment: NSDecimalNumber,
                       to address: String,
                       withFeeRate feeRate: Double,
                       rbfOption: RBFOption) -> Promise<CNBCnlibTransactionData>

  /// Transaction data for payment to a recipient with a flat, predetermined fee.
  /// Uses default `rbfOption: .Allowed`
  ///
  /// - Parameters:
  ///   - payment: Amount (as BTC NSDecimalNumber) to pay.
  ///   - address: Destination payment address.
  ///   - feeRate: Fee rate per bytes, in Satoshis
  /// - Returns: A Promise that contains a CNBCnlibTransactionData object, or rejects if failed.
  func transactionData(forPayment payment: NSDecimalNumber,
                       to address: String,
                       withFeeRate feeRate: Double) -> Promise<CNBCnlibTransactionData>

  /// Transaction data for payment to a recipient with a flat, predetermined fee.
  ///
  /// - Parameters:
  ///   - payment: Amount (in satoshis) to pay.
  ///   - address: Destination payment address.
  ///   - flatFee: Predetermined fee (NOT a rate) for the transaction
  /// - Returns: A Promise that contains a CNBCnlibTransactionData object, or rejects if failed.
  func transactionData(forPayment payment: Int,
                       to address: String,
                       withFlatFee flatFee: Int) -> Promise<CNBCnlibTransactionData>

  /// Transaction data for sending max wallet amount, minus fee, to a given address.
  /// Unconfirmed outputs (external/receive outputs only) are not included.
  /// Unconfirmed outputs (internal/change outputs only) are included.
  ///
  /// - Parameters:
  ///   - address: Destination payment address.
  ///   - feeRate: Fee rate per bytes, in Satoshis
  /// - Returns: A Promise that contains a CNBCnlibTransactionData object, or rejects if failed.
  func transactionDataSendingMax(to address: String, withFeeRate feeRate: Double) -> Promise<CNBCnlibTransactionData>

  /// Transaction data for sending max private key amount, minus fee, to a given address. Used when sweeping a private key, i.e. paper wallet.
  ///
  /// - Parameters:
  ///   - privateKey: Source private key that proves the user owns the funds.
  ///   - address: Destination address. Should be the next receive address for user's wallet.
  ///   - feeRate: Fee rate per bytes, in Satoshis
  /// - Returns: A Promise that contains a CNBCnlibTransactionData object, or rejects if failed.
  func transactionDataSendingMax(fromPrivateKey privateKey: WIFPrivateKey,
                                 to address: String,
                                 feeRate: Double) -> Promise<CNBCnlibTransactionData>

  /// Transaction data for sending all inputs, even unconfirmed, minus fee, to a given address.
  /// Used when migrating a wallet from one version to another.
  ///
  /// - Parameters:
  ///   - address: Destination payment address.
  ///   - feeRate: Fee rate per bytes, in Satoshis
  /// - Returns: A Promise that contains a CNBCnlibTransactionData object, or rejects if failed.
  func transactionDataSendingAll(to address: String, withFeeRate feeRate: Double) -> Promise<CNBCnlibTransactionData>

  func encryptPayload<T>(_ payload: T, addressPubKey: String, keyIsEphemeral: Bool) -> Promise<String> where T: SharedPayloadCodable

  func decodeLightningInvoice(_ invoiceString: String) -> Promise<LNDecodePaymentRequestResponse>
}
