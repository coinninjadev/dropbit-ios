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

  @IBOutlet var bitcoinWalletButton: UIButton!
  @IBOutlet var lightningWalletButton: UIButton!

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
    layer.cornerRadius = 5.0
    layer.borderWidth = 0.5
    layer.borderColor = UIColor.mediumGrayBackground.cgColor
    clipsToBounds = true
  }

  weak var delegate: WalletToggleViewDelegate?

  @IBAction func bitcoinWalletWasTouched() {
    delegate?.bitcoinWalletButtonWasTouched()
  }

  @IBAction func lightningWalletWasTouched() {
    delegate?.lightningWalletButtonWasTouched()
  }

}
