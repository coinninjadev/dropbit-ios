//
//  WIFPrivateKey.swift
//  DropBit
//
//  Created by Mitchell Malleo on 1/13/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Cnlib

struct WIFPrivateKey {

  private var wallet: CNBCnlibHDWallet
  private(set) var key: CNBCnlibImportedPrivateKey
  private(set) var addresses: [String]
  var isConfirmed: Bool = true

  init?(wallet: CNBCnlibHDWallet, string: String) {
    self.wallet = wallet

    let split = string.components(separatedBy: ":")
    guard let privateKeyString = split.last else { return nil }
    do {
      key = try wallet.importPrivateKey(privateKeyString)
      addresses = key.possibleAddresses.components(separatedBy: " ")
    } catch {
      return nil
    }
  }
}
