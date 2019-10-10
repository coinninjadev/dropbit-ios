//
//  TransactionDetailInvoiceCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 10/2/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class TransactionDetailInvoiceCellViewModel: TransactionDetailCellViewModel, TransactionDetailInvoiceCellViewModelType {

  let qrCodeGenerator: QRCodeGenerator
  let hoursUntilExpiration: Int?

  init(object: LightningInvoiceViewModelObject,
       inputs: TransactionViewModelInputs) {
    self.qrCodeGenerator = QRCodeGenerator()
    self.hoursUntilExpiration = object.hoursUntilExpiration
    super.init(object: object, inputs: inputs)
  }

}
