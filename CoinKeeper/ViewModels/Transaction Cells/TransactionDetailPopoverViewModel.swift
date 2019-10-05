//
//  TransactionDetailPopoverViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 10/4/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class TransactionDetailPopoverViewModel: TransactionDetailCellViewModel, TransactionDetailPopoverViewModelType {

  let txid: String

  init(object: TransactionDetailPopoverViewModelObject,
       inputs: TransactionViewModelInputs) {

    self.txid = object.txid
    super.init(object: object, inputs: inputs)
  }
}

protocol TransactionDetailPopoverViewModelObject: TransactionDetailCellViewModelObject {
  var txid: String { get }
}
