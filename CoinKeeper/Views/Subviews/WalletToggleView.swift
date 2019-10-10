//
//  WalletToggleView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol WalletToggleViewDelegate: class {
  func bitcoinWalletButtonWasTouched()
  func lightningWalletButtonWasTouched()
}

class WalletToggleView: UIView {

  @IBOutlet var bitcoinWalletButton: PrimaryActionButton!
  @IBOutlet var lightningWalletButton: PrimaryActionButton!

  weak var delegate: WalletToggleViewDelegate?

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  private func commonInit() {
    xibSetup()
    applyCornerRadius(5)
    bitcoinWalletButton.style = .bitcoin(rounded: false)
    lightningWalletButton.style = .lightning(rounded: false)
    selectBitcoinButton()
  }

  func selectBitcoinButton() {
    bitcoinWalletButton.backgroundColor = .bitcoinOrange
    bitcoinWalletButton.setAttributedTitle(NSAttributedString.bitcoinSelectedButton, for: .normal)
    deselectButton(lightningWalletButton)
  }

  func selectLightningButton() {
    lightningWalletButton.backgroundColor = .lightningBlue
    lightningWalletButton.setAttributedTitle(NSAttributedString.lightningSelectedButtonTitle, for: .normal)
    deselectButton(bitcoinWalletButton)
  }

  private func deselectButton(_ button: PrimaryActionButton) {
    button.backgroundColor = .mediumGrayBackground

    switch button {
    case bitcoinWalletButton:
      button.setAttributedTitle(NSAttributedString.bitcoinUnselectedTitle, for: .normal)
    case lightningWalletButton:
      button.setAttributedTitle(NSAttributedString.lightningUnselectedTitle, for: .normal)
    default:
      break
    }
  }

  @IBAction func bitcoinWalletWasTouched() {
    selectBitcoinButton()
    delegate?.bitcoinWalletButtonWasTouched()
  }

  @IBAction func lightningWalletWasTouched() {
    selectLightningButton()
    delegate?.lightningWalletButtonWasTouched()
  }

}
