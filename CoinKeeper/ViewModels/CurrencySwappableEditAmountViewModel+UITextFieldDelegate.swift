//
//  CurrencySwappableEditAmountViewModel+UITextFieldDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 10/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

enum EditAmountCharacterType {
  case number
  case zero
  case decimalSeparator
  case backspace

  init(string: String, decSep: String) {
    if string.isEmpty {
      self = .backspace
    } else if string == "0" {
      self = .zero
    } else if string == decSep {
      self = .decimalSeparator
    } else {
      self = .number
    }
  }
}

enum EditTextError: Error {
  case cannotAppendCharacter
  case cannotDeleteCharacter
}

extension CurrencySwappableEditAmountViewModel: UITextFieldDelegate {

  func textFieldDidBeginEditing(_ textField: UITextField) {
    delegate?.viewModelDidBeginEditingAmount(self)
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    delegate?.viewModelDidEndEditingAmount(self)
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard let currentText = textField.text, isNotDeletingOrEditingCurrencySymbol(for: currentText, in: range) else {
      return false
    }

    let newCharacterType = EditAmountCharacterType(string: string, decSep: decimalSeparator)

    let isEditingFractionalComponent = currentText.contains(decimalSeparator)

    var applyStringDirectly = false

    do {
      if isEditingFractionalComponent {
        applyStringDirectly = try shouldChangeFractionalCharacters(in: textField, with: string, ofType: newCharacterType)
      } else {
        applyStringDirectly = try shouldChangeIntegerCharacters(in: textField, with: string, ofType: newCharacterType)
      }
    } catch {
      return false
    }

    if applyStringDirectly {
      updatePrimaryAmount(with: currentText, appending: string)
      delegate?.viewModelNeedsAmountLabelRefresh(self, secondaryOnly: true)
    }

    return applyStringDirectly
  }

  private func shouldChangeFractionalCharacters(in textField: UITextField,
                                                with string: String,
                                                ofType charType: EditAmountCharacterType) throws -> Bool {
    guard let currentText = textField.text else { return false }
    let fractionalComponent = currentText.components(separatedBy: decimalSeparator).last ?? ""
    let willNotExceedDecimalPlaces = (fractionalComponent.count + string.count) <= primaryCurrency.decimalPlaces

    switch charType {
    case .decimalSeparator:
      throw EditTextError.cannotAppendCharacter
    case .backspace:
      if fractionalComponent.count == 1 { // remove last digit and decimal separator manually
        let stringToDrop = decimalSeparator + fractionalComponent
        dropStringAndRefresh(currentText: currentText, dropping: stringToDrop)
        return false
      } else {
        delegate?.viewModelNeedsAmountLabelRefresh(self, secondaryOnly: true)
        return true
      }

    case .zero:
      guard willNotExceedDecimalPlaces else { throw EditTextError.cannotAppendCharacter }
      return true

    case .number:
      guard willNotExceedDecimalPlaces else { throw EditTextError.cannotAppendCharacter }
      appendStringAndRefresh(currentText: currentText, appending: string)
      return false
    }
  }

  private func shouldChangeIntegerCharacters(in textField: UITextField,
                                             with string: String,
                                             ofType charType: EditAmountCharacterType) throws -> Bool {
    guard let currentText = textField.text else { return false }

    let symbol = primarySymbol(for: walletTransactionType)?.string ?? ""
    let currentNumberText = currentText.replacingOccurrences(of: symbol, with: "")

    switch charType {
    case .zero:
      if currentNumberText.isEmpty {
        return true
      } else if currentNumberText == "0" {
        throw EditTextError.cannotAppendCharacter
      } else {
        appendStringAndRefresh(currentText: currentText, appending: string)
        return false
      }
    case .decimalSeparator:
      if primaryRequiresInteger { throw EditTextError.cannotAppendCharacter }
      if currentNumberText == "0" {
        return true
      } else {
        //ensure leading zero if user first enters decimalSeparator
        let textToInsert = currentNumberText.isEmpty ? ("0" + decimalSeparator) : decimalSeparator
        textField.insertText(textToInsert)
        return false
      }

    case .number, .backspace:
      appendStringAndRefresh(currentText: currentText, appending: string)
      return false
    }
  }

  private func isNotDeletingOrEditingCurrencySymbol(for currentText: String, in range: NSRange) -> Bool {
    let amount = sanitizedAmount(fromRawText: currentText)
    let integerSymbol = primaryCurrency.integerSymbol(forAmount: amount)
    return (currentText != primaryCurrency.symbol || currentText != integerSymbol)
  }

  private func shouldAppendFractionalZero(currentText: String, appending string: String) -> Bool {
    guard string == "0", currentText.contains(decimalSeparator) else { return false }

    let fractionalString = currentText.components(separatedBy: decimalSeparator).last ?? ""
    return (fractionalString.count + 1) <= primaryCurrency.decimalPlaces
  }

  private func appendStringAndRefresh(currentText: String, appending string: String) {
    updatePrimaryAmount(with: currentText, appending: string)
    delegate?.viewModelNeedsAmountLabelRefresh(self, secondaryOnly: false)
  }

  private func updatePrimaryAmount(with currentText: String, appending string: String) {
    let currentSanitizedAmountString = sanitizedAmountString(currentText) ?? ""

    let newString: String
    if string.isEmpty {
      newString = String(currentSanitizedAmountString.dropLast())
    } else {
      newString = currentSanitizedAmountString + string
    }

    self.primaryAmount = NSDecimalNumber(fromString: newString) ?? .zero
  }

  private func dropStringAndRefresh(currentText: String, dropping string: String) {
    let newString = String(currentText.dropLast(string.count))
    let sanitizedNewString = sanitizedAmountString(newString) ?? ""
    self.primaryAmount = NSDecimalNumber(fromString: sanitizedNewString) ?? .zero
    delegate?.viewModelNeedsAmountLabelRefresh(self, secondaryOnly: false)
  }

}
