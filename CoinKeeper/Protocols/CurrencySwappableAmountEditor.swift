//
//  CurrencySwappableAmountEditor.swift
//  DropBit
//
//  Created by Ben Winters on 7/16/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol CurrencySwappableAmountEditor: CurrencySwappableEditAmountViewDelegate, CurrencySwappableEditAmountViewModelDelegate,
  ExchangeRateUpdateable {

  var editAmountViewModel: CurrencySwappableEditAmountViewModel { get }
  var editAmountView: CurrencySwappableEditAmountView! { get }
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
    refreshAmounts()
  }

  /// Editor should call this in response to delegate method calls of CurrencySwappableEditAmountViewModelDelegate
  func refreshAmounts() {
    let labels = editAmountViewModel.dualAmountLabels()
    editAmountView.update(with: labels)
  }

  func viewModelDidBeginEditingAmount(_ viewModel: CurrencySwappableEditAmountViewModel) {
    if viewModel.fromAmount == .zero {
      editAmountView.primaryAmountTextField.text = viewModel.fromCurrency.symbol
    }
  }

  func viewModelDidChangeAmount(_ viewModel: CurrencySwappableEditAmountViewModel) {
    //Skip updating primary text field
    updateSecondaryAmountLabel()
  }

  func updateEditAmountView(withRates rates: ExchangeRates) {
    editAmountViewModel.exchangeRates = rates
    updateSecondaryAmountLabel()
  }

  private func updateSecondaryAmountLabel() {
    let secondaryLabel = editAmountViewModel.dualAmountLabels().secondary
    editAmountView.secondaryAmountLabel.attributedText = secondaryLabel
  }

}
