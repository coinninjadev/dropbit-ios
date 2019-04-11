//
//  AppCoordinator+SelectedCurrencyUpdatable.swift
//  DropBit
//
//  Created by BJ Miller on 4/4/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension AppCoordinator: SelectedCurrencyUpdatable {
  func updateSelectedCurrency(to selectedCurrency: SelectedCurrency) {
    currencyController.selectedCurrency = selectedCurrency
  }
}
