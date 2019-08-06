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

  @IBOutlet var fiveButton: UIButton!
  @IBOutlet var twentyButton: UIButton!
  @IBOutlet var fiftyButton: UIButton!
  @IBOutlet var hundredButton: UIButton!
  @IBOutlet var customAmountButton: UIButton!

  weak var delegate: LightningTransactionHistoryEmptyViewDelegate?

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
