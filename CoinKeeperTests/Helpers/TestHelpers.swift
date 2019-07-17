//
//  TestHelpers.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit

class TestHelpers {
  static func fakeWords() -> [String] {
    return GeneratedTestWords.fakeWords
  }

  static func mockValidBitcoinAddress() -> String {
    return "15PCeM6EN7ihm4QzhVfZCeZis7uggr5RRJ"
  }

  static func mockInvalidBech32Address() -> String {
    return "BC1QW508D6QEJXTDG4Y5R3ZARVAYR0C5XW7KV8F3T4"
  }

  static func mockValidBech32Address() -> String {
    return "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4"
  }

  static func mockValidBitcoinURL(withAmount: Double) -> BitcoinURL? {
    let address = mockValidBitcoinAddress()
    let amount = NSDecimalNumber(value: 1.2)
    return BitcoinURL(address: address, amount: amount)
  }

  static func initializeWindow(with viewController: UIViewController) {
    UIApplication.shared.keyWindow?.rootViewController = viewController
  }

  static func validBase58CheckAddresses() -> [String] {
    return [
      "12vRFewBpbdiS5HXDDLEfVFtJnpA2x8NV8",
      "3EH9Wj6KWaZBaYXhVCa8ZrwpHJYtk44bGX",
      "3Cd4xEu2VvM352BVgd9cb1Ct5vxz318tVT"
    ]
  }

  static func invalidBase58CheckAddresses() -> [String] {
    return [
      "12vRFewBpbdiS5HXDDLEfVFtJnpA2",
      "12vRFewBpbdiS5HXDDLEfVFt",
      "ewBpbdiS5HXDDLEfVFtJnpA2x8NV8",
      "diS5HXDDLEfVFtJnpA2x8NV8",
      "212vRFewBpbdiS5HXDDLEfVFtJnpA2x8NV8",
      "412vRFewBpbdiS5HXDDLEfVFtJnpA2x8NV8",
      "512vRFewBpbdiS5HXDDLEfVFtJnpA2x8NV8",
      "3EH9Wj6KWaZBaYXhVCa8ZrwpHJYtk",
      "3EH9Wj6KWaZBaYXhVCa8Zrwp",
      "j6KWaZBaYXhVCa8ZrwpHJYtk44bGX",
      "ZBaYXhVCa8ZrwpHJYtk44bGX",
      "23EH9Wj6KWaZBaYXhVCa8ZrwpHJYtk44bGX",
      "43EH9Wj6KWaZBaYXhVCa8ZrwpHJYtk44bGX",
      "53EH9Wj6KWaZBaYXhVCa8ZrwpHJYtk44bGX",
      "3Cd4xEu2VvM352BVgd9cb1Ct5vxz3",
      "3Cd4xEu2VvM352BVgd9cb1Ct",
      "Eu2VvM352BVgd9cb1Ct5vxz318tVT",
      "M352BVgd9cb1Ct5vxz318tVT",
      "23Cd4xEu2VvM352BVgd9cb1Ct5vxz318tVT",
      "43Cd4xEu2VvM352BVgd9cb1Ct5vxz318tVT",
      "73Cd4xEu2VvM352BVgd9cb1Ct5vxz318tVT",
      "0xF26C29D25a1E1696c5CC54DE4bf2AEc906EB4F79", // eth address
      "qr45rul6luexjgg5h8p26c0cs6rrhwzrkg6e0hdvrf", // bch address
      "Jenny86753098675309IgotIt",
      "31415926535ILikePi89793238462643",
      "bitcoin:3Cd4xEu2VvM352BVgd9cb1Ct5vxz318tVT"
    ]
  }
}
