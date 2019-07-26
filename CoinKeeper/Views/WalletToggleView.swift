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

  private lazy var lightningTitle: NSAttributedString = {
    NSAttributedString(imageName: "flashIcon", imageSize: CGSize(width: 11, height: 18),
                       title: "Lightning", sharedColor: .white, font: .medium(14))
  }()

  private lazy var bitcoinTitle: NSAttributedString = {
    NSAttributedString(imageName: "bitcoinIconFilled", imageSize: CGSize(width: 11, height: 18),
                       title: "Bitcoin", sharedColor: .white, font: .medium(14))
  }()

  private lazy var lightningUnselectedTitle: NSAttributedString = {
    NSAttributedString(imageName: "flashIcon", imageSize: CGSize(width: 11, height: 18),
                       title: "Lightning", sharedColor: .darkGrayBackground, font: .medium(14))
  }()

  private lazy var bitcoinUnselectedTitle: NSAttributedString = {
    NSAttributedString(imageName: "bitcoinIconFilled", imageSize: CGSize(width: 11, height: 18),
                       title: "Bitcoin", sharedColor: .darkGrayBackground, font: .medium(14))
  }()

  private func commonInit() {
    xibSetup()
    layer.borderWidth = 0.5
    layer.cornerRadius = 5
    clipsToBounds = true
    layer.borderColor = UIColor.mediumGrayBackground.cgColor
    bitcoinWalletButton.style = .bitcoin
    lightningWalletButton.style = .lightning
    selectBitcoinButton()
  }

  func selectBitcoinButton() {
    bitcoinWalletButton.backgroundColor = .bitcoinOrange
    bitcoinWalletButton.setAttributedTitle(bitcoinTitle, for: .normal)
    deselectButton(lightningWalletButton)
  }

  func selectLightningButton() {
    lightningWalletButton.backgroundColor = .lightningBlue
    lightningWalletButton.setAttributedTitle(lightningTitle, for: .normal)
    deselectButton(bitcoinWalletButton)
  }

  private func deselectButton(_ button: PrimaryActionButton) {
    button.backgroundColor = .mediumGrayBackground

    switch button {
    case bitcoinWalletButton:
      button.setAttributedTitle(bitcoinUnselectedTitle, for: .normal)
    case lightningWalletButton:
      button.setAttributedTitle(lightningUnselectedTitle, for: .normal)
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
