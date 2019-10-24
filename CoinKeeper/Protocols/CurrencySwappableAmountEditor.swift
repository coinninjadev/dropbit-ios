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

  func viewModelDidBeginEditingAmount(_ viewModel: CurrencySwappableEditAmountViewModel) {
    refreshBothAmounts()
    moveCursorToCorrectLocationIfNecessary()
  }

  func viewModelDidEndEditingAmount(_ viewModel: CurrencySwappableEditAmountViewModel) {
    refreshBothAmounts()
  }

  func viewModelNeedsSecondaryAmountRefresh(_ viewModel: CurrencySwappableEditAmountViewModel) {
    refreshSecondaryAmount()
  }

  var editingIsActive: Bool {
    return editAmountView.primaryAmountTextField.isFirstResponder
  }

  /// Call this during viewDidLoad
  func setupCurrencySwappableEditAmountView() {
    editAmountView.delegate = self
    editAmountView.primaryAmountTextField.delegate = editAmountViewModel
  }

  func swapViewDidSwap(_ swapView: CurrencySwappableEditAmountView) {
    editAmountViewModel.swapPrimaryCurrency()
    refreshBothAmounts()
    moveCursorToCorrectLocationIfNecessary()
  }

  /// Editor should call this in response to delegate method calls of CurrencySwappableEditAmountViewModelDelegate
  func refreshBothAmounts() {
    let txType = editAmountViewModel.walletTransactionType
    let labels = editAmountViewModel.editableDualAmountLabels(walletTxType: txType)
    editAmountView.update(with: labels)
  }

  func moveCursorToCorrectLocationIfNecessary() {
    guard editAmountViewModel.walletTransactionType == .lightning,
      editAmountViewModel.primaryCurrency == .BTC,
      let amount = SatsFormatter().stringWithoutSymbol(fromDecimal: editAmountViewModel.primaryAmount),
      let newPosition = editAmountView.primaryAmountTextField.position(from:
        editAmountView.primaryAmountTextField.beginningOfDocument, offset: amount.count) else { return }

    if editAmountViewModel.primaryAmount == .zero {
      editAmountView.primaryAmountTextField.selectedTextRange = editAmountView.primaryAmountTextField.textRange(
        from: editAmountView.primaryAmountTextField.beginningOfDocument,
        to: editAmountView.primaryAmountTextField.beginningOfDocument)
    } else {
      editAmountView.primaryAmountTextField.selectedTextRange = editAmountView.primaryAmountTextField.textRange(from: newPosition, to: newPosition)
    }
  }

  func viewModelNeedsAmountLabelRefresh(_ viewModel: CurrencySwappableEditAmountViewModel, secondaryOnly: Bool) {
    if secondaryOnly {
      refreshSecondaryAmount()
    } else {
      refreshBothAmounts()
    }

    updateQRImage()
  }

  func updateQRImage() { } // empty default method

  func updateEditAmountView(withRates rates: ExchangeRates) {
    editAmountViewModel.exchangeRates = rates
    refreshSecondaryAmount()
  }

  private func refreshSecondaryAmount() {
    let walletTxType = editAmountViewModel.walletTransactionType
    let secondaryLabel = editAmountViewModel.editableDualAmountLabels(walletTxType: walletTxType).secondary
    editAmountView.secondaryAmountLabel.attributedText = secondaryLabel
  }

}
