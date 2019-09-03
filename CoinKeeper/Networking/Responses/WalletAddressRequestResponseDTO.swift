//
//  WalletAddressRequestResponseDTO.swift
//  DropBit
//
//  Created by BJ Miller on 7/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit

enum WalletAddressRequestResponseDTOKey: String, KeyPathDescribable {
  typealias ObjectType = WalletAddressRequestResponseDTO
  case transactionData, txid
}

class WalletAddressRequestResponseDTO {
  var transactionData: CNBTransactionData?
  var txid: String?
}
