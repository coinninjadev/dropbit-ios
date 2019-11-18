//
//  LoadLightningBalancesView.swift
//  DropBit
//
//  Created by Ben Winters on 11/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class LoadLightningBalancesView: UIView {

  @IBOutlet var containerView: UIView!
  @IBOutlet var onChainBalanceLabel: PaddedLabel!
  @IBOutlet var lightningBalanceLabel: PaddedLabel!
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    initialize()
  }

  private func initialize() {
    onChainBalanceLabel.backgroundColor = .bitcoinOrange
    lightningBalanceLabel.backgroundColor = .lightningBlue
  }

  ///Balances should be converted to fiat before calling this function
  func configure(withFiatBalances balances: WalletBalances, currency: CurrencyCode) {

  }

}
