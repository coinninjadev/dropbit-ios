//
//  TransactionSummaryCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 7/30/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

struct TransactionSummaryCellViewModel: TransactionSummaryCellViewModelType {
  var walletTxType: WalletTransactionType
  var selectedCurrency: SelectedCurrency
  var direction: TransactionDirection
  var isLightningTransfer: Bool
  var status: TransactionStatus
  var amountDetails: TransactionAmountDetails
  var memo: String?

  var counterpartyConfig: TransactionCellCounterpartyConfig?
  var receiverAddress: String?
  var lightningInvoice: String?

  init(managedTx: CKMTransaction,
       selectedCurrency: SelectedCurrency,
       lightningLoadAddress: String?) {
    self.walletTxType = .onChain
    self.selectedCurrency = selectedCurrency
    self.direction = managedTx.isIncoming ? .in : .out


    self.memo = managedTx.memo
  }

}
// MARK: - Computed Amounts
extension CKMTransaction {

  /// networkFee is calculated in Satoshis, should be sum(vin) - sum(vout), but only vin/vout pertaining to our addresses
  var networkFee: Int {
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

  /// Net effect of the transaction on the wallet of current user, returned in Satoshis
  var netWalletAmount: Int {
    if let tx = temporarySentTransaction {
      return (tx.amount + tx.feeAmount) * -1 // negative, to show an outgoing amount with a negative impact on wallet balance
    }

    if vins.isEmpty && vouts.isEmpty, let invite = invitation { // Incoming invitation without valid transaction
      return invite.btcAmount
    }

    return myVouts - myVins
  }

  /// The amount received after the network fee has been subtracted from the sent amount
  var receivedAmount: Int {
    return isIncoming ? netWalletAmount : (abs(netWalletAmount) - networkFee)
  }

  /// Returns sum of `amount` value from all vins
  private var sumVins: Int {
    return NSArray(array: vins.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

  /// Returns sum of `amount` value from all vouts
  private var sumVouts: Int {
    return NSArray(array: vouts.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

  /// Returns sent amount from vins, relative to addresses owned by user's wallet
  private var myVins: Int {
    let vinsToUse = vins.filter { $0.belongsToWallet }
    return NSArray(array: vinsToUse.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

  /// Returns received amount from vouts, relative to addresses owned by user's wallet
  private var myVouts: Int {
    let voutsToUse = vouts.filter { $0.address != nil }
    return NSArray(array: voutsToUse.asArray()).value(forKeyPath: "@sum.amount") as? Int ?? 0
  }

}
