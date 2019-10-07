//
//  TransactionAmountsFactory.swift
//  DropBit
//
//  Created by Ben Winters on 10/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/// The net amounts represent the net impact to the user's balance.
/// As such, they include fees if on the sender side and they are known.
/// The net amount is intended to be displayed to the user without further adjustments for fees.
protocol TransactionAmountsFactoryType {

  var netAtCurrentAmounts: ConvertedAmounts { get }

  /// The amounts when the invitation or lightning invoice was originally created.
  var netWhenInitiatedAmounts: ConvertedAmounts? { get }

  /// The amounts when the transaction was executed.
  var netWhenTransactedAmounts: ConvertedAmounts? { get }

  /// The amount received by the on-chain wallet, after deducting all fees
  var netWithdrawalAmounts: ConvertedAmounts? { get }

  var bitcoinNetworkFeeAmounts: ConvertedAmounts? { get }
  var lightningNetworkFeeAmounts: ConvertedAmounts? { get }
  var dropBitFeeAmounts: ConvertedAmounts? { get }

}

/// A container to hold the output of the factory to prevent unnecessary recalculation
struct TransactionAmounts {

  let netAtCurrent: ConvertedAmounts
  let netWhenInitiated: ConvertedAmounts?
  let netWhenTransacted: ConvertedAmounts?
  let netWithdrawalAmounts: ConvertedAmounts?
  let bitcoinNetworkFee: ConvertedAmounts?
  let lightningNetworkFee: ConvertedAmounts?
  let dropBitFee: ConvertedAmounts?

  init(factory: TransactionAmountsFactoryType) {
    self.netAtCurrent = factory.netAtCurrentAmounts
    self.netWhenInitiated = factory.netWhenInitiatedAmounts
    self.netWhenTransacted = factory.netWhenTransactedAmounts
    self.netWithdrawalAmounts = factory.netWithdrawalAmounts
    self.bitcoinNetworkFee = factory.bitcoinNetworkFeeAmounts
    self.lightningNetworkFee = factory.lightningNetworkFeeAmounts
    self.dropBitFee = factory.dropBitFeeAmounts
  }

}

struct TransactionAmountsFactory: TransactionAmountsFactoryType {

  private let fiatCurrency: CurrencyCode
  private let currentRate: Double
  private let walletTxType: WalletTransactionType
  private let transferType: LightningTransferType?

  ///This value may be positive or negative depending on how it affects the balance
  private let netWalletAmount: NSDecimalNumber

  private var rateWhenTransacted: Double?
  private var primaryFiatAmountWhenInitiated: NSDecimalNumber? //already converted
  private var bitcoinNetworkFee: NSDecimalNumber?
  private var lightningNetworkFee: NSDecimalNumber?
  private var dropBitFee: NSDecimalNumber?

  init(transaction: CKMTransaction,
       fiatCurrency: CurrencyCode,
       currentRates: ExchangeRates,
       transferType: LightningTransferType?) {
    self.fiatCurrency = fiatCurrency
    self.currentRate = currentRates[fiatCurrency] ?? 1
    self.walletTxType = .onChain
    self.transferType = transferType

    self.netWalletAmount = NSDecimalNumber(integerAmount: transaction.netWalletAmount, currency: .BTC)
    self.bitcoinNetworkFee = NSDecimalNumber(integerAmount: transaction.networkFee, currency: .BTC)
    self.rateWhenTransacted = transaction.dayAveragePrice?.doubleValue
    if let invite = transaction.invitation {
      primaryFiatAmountWhenInitiated = NSDecimalNumber(integerAmount: invite.fiatAmount, currency: .USD)
    }
  }

  init(walletEntry: CKMWalletEntry,
       fiatCurrency: CurrencyCode,
       currentRates: ExchangeRates,
       transferType: LightningTransferType?) {
    self.fiatCurrency = fiatCurrency
    self.currentRate = currentRates[fiatCurrency] ?? 1
    self.walletTxType = .lightning
    self.transferType = transferType

    self.netWalletAmount = NSDecimalNumber(integerAmount: walletEntry.netWalletAmount, currency: .BTC)

    if let ledgerEntry = walletEntry.ledgerEntry {
      switch ledgerEntry.type {
      case .btc:
        self.bitcoinNetworkFee = NSDecimalNumber(integerAmount: ledgerEntry.networkFee, currency: .BTC)
      case .lightning:
        self.lightningNetworkFee = NSDecimalNumber(integerAmount: ledgerEntry.networkFee, currency: .BTC)
      }

      self.dropBitFee = NSDecimalNumber(integerAmount: ledgerEntry.processingFee, currency: .BTC)
    }

    if let invite = walletEntry.invitation {
      self.primaryFiatAmountWhenInitiated = NSDecimalNumber(integerAmount: invite.fiatAmount, currency: .USD)
    }
  }

  var netAtCurrentAmounts: ConvertedAmounts {
    return convertedAmounts(withRate: currentRate, btcAmount: netWalletAmount)
  }

  var netWhenInitiatedAmounts: ConvertedAmounts? {
    guard let fiatAmount = primaryFiatAmountWhenInitiated else { return nil }
    return ConvertedAmounts(btc: netWalletAmount, fiat: fiatAmount, fiatCurrency: fiatCurrency)
  }

  var netWhenTransactedAmounts: ConvertedAmounts? {
    guard let rate = rateWhenTransacted else { return nil }
    return convertedAmounts(withRate: rate, btcAmount: netWalletAmount)
  }

  var totalWithdrawalAmounts: ConvertedAmounts? {
    guard let type = transferType, type == .withdraw else { return nil }
    let totalBTCAmount: NSDecimalNumber
    switch walletTxType {
    case .onChain:
      //This reverses the logic performed by netWalletAmount in the CKMTransaction and CKMWalletEntry extensions
      //That logic is needed there by the other ConvertedAmounts that are not withdrawals.
      totalBTCAmount = netWalletAmount.adding(totalFees)
    case .lightning:
      totalBTCAmount = netWalletAmount
    }
    return convertedAmounts(withRate: currentRate, btcAmount: totalBTCAmount)
  }

  var netWithdrawalAmounts: ConvertedAmounts? {
    guard let type = transferType, type == .withdraw else { return nil }
    let totalBTCAmount: NSDecimalNumber
    switch walletTxType {
    case .onChain:
      totalBTCAmount = netWalletAmount
    case .lightning:
      //This reverses the logic performed by netWalletAmount in the CKMTransaction and CKMWalletEntry extensions
      //That logic is needed there by the other ConvertedAmounts that are not withdrawals.
      totalBTCAmount = netWalletAmount.subtracting(totalFees)
    }
    return convertedAmounts(withRate: currentRate, btcAmount: totalBTCAmount)
  }

  var bitcoinNetworkFeeAmounts: ConvertedAmounts? {
    guard let fee = bitcoinNetworkFee else { return nil }
    return convertedAmounts(withRate: currentRate, btcAmount: fee)
  }

  var lightningNetworkFeeAmounts: ConvertedAmounts? {
    guard let fee = lightningNetworkFee else { return nil }
    return convertedAmounts(withRate: currentRate, btcAmount: fee)
  }

  var dropBitFeeAmounts: ConvertedAmounts? {
    guard let fee = dropBitFee else { return nil }
    return convertedAmounts(withRate: currentRate, btcAmount: fee)
  }

  private func convertedAmounts(withRate rate: Double, btcAmount: NSDecimalNumber) -> ConvertedAmounts {
    let converter = CurrencyConverter(fromBtcTo: fiatCurrency,
                                      fromAmount: btcAmount,
                                      rates: [.BTC: 1, fiatCurrency: rate])
    return ConvertedAmounts(converter: converter)
  }

  private var totalFees: NSDecimalNumber {
    let onChainFee = bitcoinNetworkFee ?? .zero
    let lightningFee = lightningNetworkFee ?? .zero
    let dbFee = dropBitFee ?? .zero
    return onChainFee.adding(lightningFee).adding(dbFee)
  }

}

typealias Satoshis = Int

// MARK: - Computed Amounts
extension CKMTransaction {

  /// should be sum(vin) - sum(vout), but only vin/vout pertaining to our addresses
  var networkFee: Satoshis {
    if let tempTransaction = temporarySentTransaction {
      return tempTransaction.feeAmount
    } else if let invitation = invitation {
      switch invitation.status {
      case .requestSent: return invitation.fees
      default: break
      }
    }
    return sumVins - sumVouts
  }

  /// Net effect of the transaction on the wallet of current user
  var netWalletAmount: Satoshis {
    if let tx = temporarySentTransaction {
      return (tx.amount + tx.feeAmount) * -1 // negative, to show an outgoing amount with a negative impact on wallet balance
    }

    if vins.isEmpty && vouts.isEmpty, let invite = invitation { // Incoming invitation without valid transaction
      return invite.btcAmount
    }

    return myVouts - myVins
  }

  /// The amount received after the network fee has been subtracted from the sent amount
  var receivedAmount: Satoshis {
    return isIncoming ? netWalletAmount : (abs(netWalletAmount) - networkFee)
  }

  /// Returns sum of `amount` value from all vins
  private var sumVins: Satoshis {
    return NSArray(array: vins.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

  /// Returns sum of `amount` value from all vouts
  private var sumVouts: Satoshis {
    return NSArray(array: vouts.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

  /// Returns sent amount from vins, relative to addresses owned by user's wallet
  private var myVins: Satoshis {
    let vinsToUse = vins.filter { $0.belongsToWallet }
    return NSArray(array: vinsToUse.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

  /// Returns received amount from vouts, relative to addresses owned by user's wallet
  private var myVouts: Satoshis {
    let voutsToUse = vouts.filter { $0.address != nil }
    return NSArray(array: voutsToUse.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

}

extension CKMWalletEntry {

  var netWalletAmount: Satoshis {
    if let ledgerEntry = self.ledgerEntry {
      switch ledgerEntry.direction {
      case .in:
        return ledgerEntry.value
      case .out:
        let totalAmount = ledgerEntry.value + ledgerEntry.networkFee + ledgerEntry.processingFee
        return totalAmount * -1
      }

    } else if let invitation = self.invitation {
      let sign = invitation.side == .receiver ? 1 : -1
      return invitation.btcAmount * sign

    } else {
      return 0
    }
  }

}
