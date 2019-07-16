//
//  CurrencySwappableAmountEditor.swift
//  DropBit
//
//  Created by Ben Winters on 7/16/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol CurrencySwappableAmountEditor: CurrencySwappableEditAmountViewDelegate {
  var editAmountViewModel: CurrencySwappableEditAmountViewModel { get }
  var editAmountView: CurrencySwappableEditAmountView { get }
}

extension CurrencySwappableAmountEditor {

  func swapViewDidSwap(_ swapView: CurrencySwappableEditAmountView) {
    editAmountViewModel.swapPrimaryCurrency()
    let labels = editAmountViewModel.amountLabels(withSymbols: true)
    editAmountView.update(labels)
  }

}
