//
// Created by BJ Miller on 2/23/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit

class MockDigitEntryDisplayViewModel: DigitEntryDisplayViewModelType {

  var digitWasAdded = false
  var maxCount: UInt
  func add(digit: String) -> AddDigitResult {
    if allDigitsEntered { return .exceeded }

    digitWasAdded = true
    digits.append(digit)

    return allDigitsEntered ? .complete : .incomplete
  }

  var digitWasRemoved = false
  func removeDigit() {
    digitWasRemoved = true
    digits.removeLast()
  }

  var digitsWereRemoved = false
  func removeAllDigits() {
    digitsWereRemoved = true
    digits = ""
  }

  var digits: String = ""

  var allDigitsEntered: Bool {
    return digits.count == 6
  }

  let view: PinDisplayable
  required init(view: PinDisplayable, maxDigits: UInt = 6) {
    self.maxCount = maxDigits
    self.view = view
  }
}
