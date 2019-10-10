//
//  OnChainPopoverViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 10/4/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class OnChainPopoverViewModel: TransactionDetailCellViewModel, TransactionDetailPopoverViewModelType {

  let txid: String

  init(object: OnChainPopoverViewModelObject,
       inputs: TransactionViewModelInputs) {

    self.txid = object.txid
    super.init(object: object, inputs: inputs)
  }
}

protocol OnChainPopoverViewModelObject: TransactionDetailCellViewModelObject {
  var txid: String { get }
}

///View model object where ledgerEntry.type == .btc.
///This object can be used to initialize an OnChainPopoverViewModel.
class LightningOnChainViewModelObject: LightningTransactionViewModelObject, OnChainPopoverViewModelObject {

  let txid: String

  override init?(walletEntry: CKMWalletEntry) {
    guard let ledgerEntry = walletEntry.ledgerEntry, ledgerEntry.type == .btc,
      let txid = ledgerEntry.id
      else { return nil }

    self.txid = txid
    super.init(walletEntry: walletEntry)
  }
}
