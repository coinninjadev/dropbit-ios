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

@IBDesignable
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
    layer.borderWidth = 0.5
    layer.cornerRadius = 5
    clipsToBounds = true
    layer.borderColor = UIColor.mediumGrayBackground.cgColor
    selectBitcoinButton()
    lightningWalletButton.applyCornerRadius(0)
    deselectButton(lightningWalletButton)
  }

  func selectBitcoinButton() {
    bitcoinWalletButton.style = .bitcoin
    deselectButton(lightningWalletButton)
  }

  func selectLightningButton() {
    lightningWalletButton.style = .lightning
    deselectButton(bitcoinWalletButton)
  }

  private func deselectButton(_ button: UIButton) {
    button.backgroundColor = .lightGray
    button.setTitleColor(.mediumGrayBackground, for: .normal)
    button.tintColor = .mediumGrayBackground
    button.imageView?.tintColor = .mediumGrayBackground
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
