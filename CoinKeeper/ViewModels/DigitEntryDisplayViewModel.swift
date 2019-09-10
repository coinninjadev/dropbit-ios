//
//  DigitEntryDisplayViewModel.swift
//  DropBit
//
//  Created by BJ Miller on 2/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol DigitEntryDisplayViewModelType: AnyObject {
  func add(digit: String) -> AddDigitResult
  func removeDigit()
  func removeAllDigits()
  var digits: String { get }
  init(view: PinDisplayable, maxDigits: UInt)
}

enum AddDigitResult: String, CustomStringConvertible {
  /// maxCount not yet met
  case incomplete

  /// maxCount is newly met
  case complete

  /// maxCount was previously met
  case exceeded

  var description: String {
    return "AddDigitResult." + rawValue
  }

}

class DigitEntryDisplayViewModel: DigitEntryDisplayViewModelType {
  private(set) var digits: String = ""
  let minCount = 0
  var maxCount: UInt

  private let view: PinDisplayable

  required init(view: PinDisplayable, maxDigits: UInt = 6) {
    self.maxCount = min(maxDigits, 64) // a little bulletproofing; we don't need UInt.max
    self.view = view
  }

  func add(digit: String) -> AddDigitResult {
    if allDigitsEntered { return .exceeded } // adding a digit would exceed the maxCount

    digits.append(digit)
    view.setDigits(digits)

    return allDigitsEntered ? .complete : .incomplete
  }

  var allDigitsEntered: Bool {
    return digits.count == Int(maxCount)
  }

  func removeDigit() {
    guard !digits.isEmpty else { return }
    digits.removeLast()
    view.setDigits(digits)
  }

  func removeAllDigits() {
    digits.removeAll()
    view.setDigits(digits)
  }
}
