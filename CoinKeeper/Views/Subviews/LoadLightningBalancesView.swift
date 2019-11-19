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
  @IBOutlet var onChainBalanceLabel: LightningLoadBalanceLabel!
  @IBOutlet var lightningBalanceLabel: LightningLoadBalanceLabel!

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
    initialize()
  }

  private func initialize() {
    onChainBalanceLabel.backgroundColor = .bitcoinOrange
    lightningBalanceLabel.backgroundColor = .lightningBlue
    let radius = frame.height / 2
    onChainBalanceLabel.applyCornerRadius(radius)
    lightningBalanceLabel.applyCornerRadius(radius)
  }

  ///Balances should be converted to fiat before calling this function
  func configure(withFiatBalances balances: WalletBalances, currency: CurrencyCode) {
    let formatter = FiatFormatter(currency: currency, withSymbol: true)
    let onChainAmount = formatter.string(fromDecimal: balances.onChain) ?? "-"
    let lightningAmount = formatter.string(fromDecimal: balances.lightning) ?? "-"
    onChainBalanceLabel.attributedText = balanceTitle(withFormattedAmount: onChainAmount, type: .onChain)
    lightningBalanceLabel.attributedText = balanceTitle(withFormattedAmount: lightningAmount, type: .lightning)
  }

  private func balanceTitle(withFormattedAmount amount: String, type: WalletTransactionType) -> NSAttributedString {
    let imageName: String
    switch type {
    case .onChain:    imageName = "bitcoinIconFilled"
    case .lightning:  imageName = "flashIcon"
    }
    return NSAttributedString(imageName: imageName, imageSize: CGSize(width: 11, height: 14),
                              title: amount, sharedColor: .white, font: .medium(14),
                              titleOffset: 1, imageOffset: CGPoint(x: 0, y: 2), spaceCount: 1)
  }

}
