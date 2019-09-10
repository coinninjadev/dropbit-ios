//
//  CurrencySwappableAmountEditor.swift
//  DropBit
//
//  Created by Ben Winters on 7/16/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol CurrencySwappableAmountEditor: CurrencySwappableEditAmountViewDelegate, CurrencySwappableEditAmountViewModelDelegate,
  ExchangeRateUpdatable {

  var editAmountViewModel: CurrencySwappableEditAmountViewModel { get }
  var editAmountView: CurrencySwappableEditAmountView! { get }

  func updateQRImage()
}

extension CurrencySwappableAmountEditor {

  /// Call this during viewDidLoad
  func setupCurrencySwappableEditAmountView() {
    editAmountView.delegate = self
    editAmountView.primaryAmountTextField.delegate = editAmountViewModel

    let textFieldDidChangeAction = #selector(CurrencySwappableEditAmountViewModel.primaryAmountTextFieldDidChange)
    editAmountView.primaryAmountTextField.addTarget(editAmountViewModel,
                                                    action: textFieldDidChangeAction,
                                                    for: .editingChanged)
  }

  func swapViewDidSwap(_ swapView: CurrencySwappableEditAmountView) {
    editAmountViewModel.swapPrimaryCurrency()
    refreshBothAmounts()
    moveCursorToCorrectLocationIfNecessary()
  }

  /// Editor should call this in response to delegate method calls of CurrencySwappableEditAmountViewModelDelegate
  func refreshBothAmounts() {
    let shouldHideZero = editAmountView.primaryAmountTextField.isFirstResponder
    let txType = editAmountViewModel.walletTransactionType
    let labels = editAmountViewModel.dualAmountLabels(hidePrimaryZero: shouldHideZero, walletTransactionType: txType)
    editAmountView.update(with: labels)

  }

  private func moveCursorToCorrectLocationIfNecessary() {
    guard editAmountViewModel.walletTransactionType == .lightning,
      editAmountViewModel.primaryCurrency == .BTC,
      let newPosition = editAmountView.primaryAmountTextField.position(from:
        editAmountView.primaryAmountTextField.beginningOfDocument, offset: amount.count) else { return }
      editAmountView.primaryAmountTextField.selectedTextRange = editAmountView.primaryAmountTextField.textRange(from: newPosition, to: newPosition)
  }

  func refreshSecondaryAmount() {
    let secondaryLabel = editAmountViewModel.dualAmountLabels(walletTransactionType: editAmountViewModel.walletTransactionType).secondary
    editAmountView.secondaryAmountLabel.attributedText = secondaryLabel
  }

  func viewModelDidChangeAmount(_ viewModel: CurrencySwappableEditAmountViewModel) {
    //Skip updating primary text field
    refreshSecondaryAmount()
    updateQRImage()
  }

  func updateQRImage() { } // empty default method

  func updateEditAmountView(withRates rates: ExchangeRates) {
    editAmountViewModel.exchangeRates = rates
    refreshSecondaryAmount()
  }

}
