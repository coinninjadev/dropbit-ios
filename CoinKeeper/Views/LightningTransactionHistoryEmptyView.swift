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
  func emptyViewDidRequestCustomAmount()
  func emptyViewDidRequestRefill(withAmount amount: LightningTransactionHistoryEmptyView.Amount)
}

class LightningTransactionHistoryEmptyView: UIView {
  enum Amount {
    case five
    case twenty
    case fifty
    case hundred
  }

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var fiveButton: PrimaryActionButton!
  @IBOutlet var twentyButton: PrimaryActionButton!
  @IBOutlet var fiftyButton: PrimaryActionButton!
  @IBOutlet var hundredButton: PrimaryActionButton!
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

    styleButton(button: fiveButton)
    styleButton(button: twentyButton)
    styleButton(button: fiftyButton)
    styleButton(button: hundredButton)
  }

  private func styleButton(button: UIButton) {
    button.backgroundColor = .lightningBlue
    button.setTitleColor(.white, for: .normal)
    button.titleLabel?.font = .medium(18)
    button.applyCornerRadius(5)
  }

  @IBAction func fiveButtonWasTouched() {
    delegate?.emptyViewDidRequestRefill(withAmount: .five)
  }

  @IBAction func twentyButtonWasTouched() {
    delegate?.emptyViewDidRequestRefill(withAmount: .twenty)
  }

  @IBAction func fiftyButtonWasTouched() {
    delegate?.emptyViewDidRequestRefill(withAmount: .fifty)
  }

  @IBAction func hundredButtonWasTouched() {
    delegate?.emptyViewDidRequestRefill(withAmount: .hundred)
  }

  @IBAction func customAmountButtonWasTouched() {
    delegate?.emptyViewDidRequestCustomAmount()
  }

}
