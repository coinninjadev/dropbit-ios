//
//  LightningTransactionHistoryEmptyView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol LightningTransactionHistoryEmptyViewDelegate: AnyObject {
  func emptyViewDidRequestRefill(withAmount amount: TransferAmount)
}

class LightningTransactionHistoryEmptyView: UIView {

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var lowAmountButton: LightningActionButton!
  @IBOutlet var mediumAmountButton: LightningActionButton!
  @IBOutlet var highAmountButton: LightningActionButton!
  @IBOutlet var maxAmountButton: LightningActionButton!
  @IBOutlet var customAmountButton: UIButton!

  weak var delegate: LightningTransactionHistoryEmptyViewDelegate?

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

  @IBAction func lowAmountButtonWasTouched() {
    delegate?.emptyViewDidRequestRefill(withAmount: .low)
  }

  @IBAction func mediumAmountButtonWasTouched() {
    delegate?.emptyViewDidRequestRefill(withAmount: .medium)
  }

  @IBAction func highAmountButtonWasTouched() {
    delegate?.emptyViewDidRequestRefill(withAmount: .high)
  }

  @IBAction func maxAmountButtonWasTouched() {
    delegate?.emptyViewDidRequestRefill(withAmount: .max)
  }

  @IBAction func customAmountButtonWasTouched() {
    delegate?.emptyViewDidRequestRefill(withAmount: .custom)
  }

}
