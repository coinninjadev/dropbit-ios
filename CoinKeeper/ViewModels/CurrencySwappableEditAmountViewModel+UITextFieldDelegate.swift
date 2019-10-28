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

    do {
      if isEditingFractionalComponent {
        try shouldChangeFractionalCharacters(in: textField, with: string, ofType: newCharacterType)
      } else {
        try shouldChangeIntegerCharacters(in: textField, with: string, ofType: newCharacterType)
      }
    } catch {
      return false
    }

    return false
  }

  private func shouldChangeIntegerCharacters(in textField: UITextField,
                                             with string: String,
                                             ofType charType: EditAmountCharacterType) throws {
    guard let currentText = textField.text else { return }

    let symbol = primarySymbol(for: walletTransactionType)?.string ?? ""
    let currentNumberText = currentText.replacingOccurrences(of: symbol, with: "")

    switch charType {
    case .zero:
      if currentNumberText.isEmpty {
        if primaryRequiresInteger { //proxy for sats
          throw EditTextError.cannotAppendCharacter
        } else {
          applyStringDirectly(textField: textField, newString: string)
        }
      } else if currentNumberText == "0" {
        throw EditTextError.cannotAppendCharacter
      } else {
        updateAmountAndRefresh(currentText: currentText, appending: string)
      }
    case .decimalSeparator:
      if primaryRequiresInteger { throw EditTextError.cannotAppendCharacter }
      //ensure leading zero if user first enters decimalSeparator
      let textToAppend = currentNumberText.isEmpty ? ("0" + decimalSeparator) : decimalSeparator
      applyStringDirectly(textField: textField, newString: textToAppend)

    case .number, .backspace:
      updateAmountAndRefresh(currentText: currentText, appending: string)
    }
  }

  private func shouldChangeFractionalCharacters(in textField: UITextField,
                                                with string: String,
                                                ofType charType: EditAmountCharacterType) throws {
    guard let currentText = textField.text else { return }
    let fractionalComponent = currentText.components(separatedBy: decimalSeparator).last ?? ""
    let willNotExceedDecimalPlaces = (fractionalComponent.count + string.count) <= primaryCurrency.decimalPlaces

    switch charType {
    case .decimalSeparator:
      throw EditTextError.cannotAppendCharacter
    case .backspace:
      if fractionalComponent.count == 1 { // remove last digit and decimal separator manually
        let stringToDrop = decimalSeparator + fractionalComponent
        dropStringAndRefresh(currentText: currentText, dropping: stringToDrop)
      } else {
        applyStringDirectly(textField: textField, newString: string)
      }

    case .zero:
      guard willNotExceedDecimalPlaces else { throw EditTextError.cannotAppendCharacter }
      applyStringDirectly(textField: textField, newString: string)

    case .number:
      guard willNotExceedDecimalPlaces else { throw EditTextError.cannotAppendCharacter }
      updateAmountAndRefresh(currentText: currentText, appending: string)
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

  private func updateAmountAndRefresh(currentText: String, appending string: String) {
    let currentSanitizedAmountString = sanitizedAmountString(currentText) ?? ""

    let newString: String
    if string.isEmpty {
      newString = String(currentSanitizedAmountString.dropLast())
    } else {
      newString = currentSanitizedAmountString + string
    }

    self.primaryAmount = NSDecimalNumber(fromString: newString) ?? .zero

    delegate?.viewModelNeedsAmountLabelRefresh(self, secondaryOnly: false)
  }

  private func applyStringDirectly(textField: UITextField, newString: String) {
    guard let currentText = textField.attributedText else { return }
    let newString = createNewAttributedString(from: currentText, applying: newString)
    textField.attributedText = newString
    self.primaryAmount = sanitizedAmount(fromRawText: newString.string)
    delegate?.viewModelNeedsAmountLabelRefresh(self, secondaryOnly: true)
  }

  ///Applies the character (or backspace) to the current attributed string, without reformatting the string as a whole.
  ///This is useful when typing backspaces and zeroes.
  private func createNewAttributedString(from currentString: NSAttributedString, applying newString: String) -> NSAttributedString {
    let mutableString = NSMutableAttributedString(attributedString: currentString)
    if newString.isEmpty {
      mutableString.deleteCharacters(in: NSRange(location: mutableString.length - 1, length: 1))
      mutableString.increaseSizeIfAble(to: standardPrimaryFontSize, maxWidth: maxPrimaryWidth)
    } else {
      let characterAttributes = attributesForAppendingCharacter(to: currentString)
      let formattedCharacter = NSAttributedString(string: newString, attributes: characterAttributes)
      mutableString.append(formattedCharacter)
      mutableString.decreaseSizeIfNecessary(to: reducedPrimaryFontSize, maxWidth: maxPrimaryWidth)
    }

    return mutableString
  }

  private func attributesForAppendingCharacter(to currentText: NSAttributedString) -> StringAttributes {
    let hasNumber = (sanitizedAmountString(currentText.string) ?? "").isNotEmpty
    if hasNumber {
      //Only use these attributes if last character is not a currency symbol
      return currentText.attributes(at: currentText.length - 1, effectiveRange: nil)
    } else {
      return primaryAttributes
    }
  }

  private func dropStringAndRefresh(currentText: String, dropping string: String) {
    let newString = String(currentText.dropLast(string.count))
    let sanitizedNewString = sanitizedAmountString(newString) ?? ""
    self.primaryAmount = NSDecimalNumber(fromString: sanitizedNewString) ?? .zero
    delegate?.viewModelNeedsAmountLabelRefresh(self, secondaryOnly: false)
  }

}
