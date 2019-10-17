//
//  TransactionDetailInvalidCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 10/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class TransactionDetailInvalidCellViewModel: TransactionDetailCellViewModel, TransactionDetailInvalidCellViewModelType {

  init?(maybeInvalidObject object: TransactionDetailCellViewModelObject,
        inputs: TransactionViewModelInputs) {
    guard !object.status.isValid else { return nil }
    super.init(object: object, inputs: inputs)
  }

}
