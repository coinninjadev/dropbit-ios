//
//  LightningTransactionHistoryEmptyView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class LightningTransactionHistoryEmptyView: UIView {

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var lowAmountButton: LightningActionButton!
  @IBOutlet var mediumAmountButton: LightningActionButton!
  @IBOutlet var highAmountButton: LightningActionButton!
  @IBOutlet var maxAmountButton: LightningActionButton!
  @IBOutlet var customAmountButton: UIButton!

  weak var delegate: LightningReloadDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()

    titleLabel.font = .medium(17)
    titleLabel.textColor = .darkGrayText

    detailLabel.font = .regular(12)
    detailLabel.textColor = .lightningBlue

    customAmountButton.titleLabel?.textColor = .darkGrayText
    customAmountButton.tintColor = .darkGray
    customAmountButton.titleLabel?.font = .medium(16)
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: 404, height: 221)
  }

  @IBAction func lowAmountButtonWasTouched() {
    delegate?.didRequestLightningLoad(withAmount: .low)
  }

  @IBAction func mediumAmountButtonWasTouched() {
    delegate?.didRequestLightningLoad(withAmount: .medium)
  }

  @IBAction func highAmountButtonWasTouched() {
    delegate?.didRequestLightningLoad(withAmount: .high)
  }

  @IBAction func maxAmountButtonWasTouched() {
    delegate?.didRequestLightningLoad(withAmount: .max)
  }

  @IBAction func customAmountButtonWasTouched() {
    delegate?.didRequestLightningLoad(withAmount: .custom)
  }

}
