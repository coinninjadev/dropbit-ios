//
//  CKPhoneNumberTextField.swift
//  DropBit
//
//  Created by Ben Winters on 2/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PhoneNumberKit

protocol CKPhoneNumberTextFieldDelegate: AnyObject {
  func textFieldReceivedValidMobileNumber(_ phoneNumber: GlobalPhoneNumber, textField: CKPhoneNumberTextField)
  func textFieldReceivedInvalidMobileNumber(_ phoneNumber: GlobalPhoneNumber, textField: CKPhoneNumberTextField)
}

class CKPhoneNumberTextField: PhoneNumberTextField {

  weak var phoneNumberTextFieldDelegate: CKPhoneNumberTextFieldDelegate?
  var enteredText: String = ""

  private let kit = PhoneNumberKit()

  private var countryCode: Int = 1
  private let defaultMaxNationalDigits = 12

  private func maxNationalDigits() -> Int {
    let possibleLengths = kit.possiblePhoneNumberLengths(forCountry: defaultRegion, phoneNumberType: .mobile, lengthType: .national)
    return possibleLengths.max() ?? defaultMaxNationalDigits
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  private func setup() {
    textColor = .grayText
    font = CKFont.regular(14)
  }

  func update(withCountry country: CKCountry, nationalNumber natl: String? = nil) {
    self.countryCode = country.countryCode
    self.defaultRegion = country.regionCode
    self.maxDigits = maxNationalDigits()
    setText(withCountryCode: countryCode, nationalNumber: natl ?? nationalNumber)
  }

  func currentGlobalNumber() -> GlobalPhoneNumber {
    return GlobalPhoneNumber(countryCode: self.countryCode, nationalNumber: self.nationalNumber)
  }

  private func setText(withCountryCode code: Int, nationalNumber: String) {
    enteredText = nationalNumber
    self.text = GlobalPhoneNumber(countryCode: code, nationalNumber: nationalNumber).asE164()

    self.textAlignment = nationalNumber.isEmpty ? .left : .center

    let maxNationalDigits = self.maxDigits ?? defaultMaxNationalDigits
    if nationalNumber.count == maxNationalDigits {
      let globalPhoneNumber = GlobalPhoneNumber(countryCode: code,
                                                nationalNumber: nationalNumber,
                                                regionCode: defaultRegion)
      if isValidNumber {
        phoneNumberTextFieldDelegate?.textFieldReceivedValidMobileNumber(globalPhoneNumber, textField: self)
      } else {
        phoneNumberTextFieldDelegate?.textFieldReceivedInvalidMobileNumber(globalPhoneNumber, textField: self)
      }
    }
  }

  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    return false
  }

}

extension CKPhoneNumberTextField: KeypadEntryViewDelegate {

  func selected(digit: String) {
    let candidateNumber = nationalNumber + digit
    setText(withCountryCode: countryCode, nationalNumber: candidateNumber)
  }

  func selectedBack() {
    guard nationalNumber.isNotEmpty else { return }
    let newNationalNumber = String(nationalNumber.dropLast())
    setText(withCountryCode: countryCode, nationalNumber: newNationalNumber)
  }

}
