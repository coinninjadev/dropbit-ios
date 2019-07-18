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
    let labels = editAmountViewModel.amountLabels(withSymbols: true)
    editAmountView.update(with: labels)
  }

  func viewModelDidChangeAmount(_ viewModel: CurrencySwappableEditAmountViewModel) {
    //Skip updating primary text field
    let labels = viewModel.amountLabels(withSymbols: true)
    editAmountView.secondaryAmountLabel.attributedText = labels.secondary
  }

}
