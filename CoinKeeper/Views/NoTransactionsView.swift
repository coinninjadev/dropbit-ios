//
//  NoTransactionsView.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol NoTransactionsViewDelegate: AnyObject {
  func noTransactionsViewDidSelectLearnAboutBitcoin(_ view: NoTransactionsBaseView)
  func noTransactionsViewDidSelectGetBitcoin(_ view: NoTransactionsBaseView)
  func noTransactionsViewDidSelectSpendBitcoin(_ view: NoTransactionsBaseView)
}

class NoTransactionsBaseView: UIView {

  @IBOutlet var getBitcoinButton: PrimaryActionButton! {
    didSet {
      getBitcoinButton.setTitle("GET BITCOIN", for: .normal)
      getBitcoinButton.mode = .getBitcoin
    }
  }
  @IBOutlet var learnAboutBitcoinButton: PrimaryActionButton! {
    didSet {
      learnAboutBitcoinButton.setTitle("LEARN BITCOIN", for: .normal)
      learnAboutBitcoinButton.mode = .learnBitcoin
    }
  }

  weak var delegate: NoTransactionsViewDelegate?

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initalize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initalize()
  }

  private func initalize() {
    backgroundColor = Theme.Color.lightGrayBackground.color
  }

  @IBAction func learnAboutBitcoin() {
    delegate?.noTransactionsViewDidSelectLearnAboutBitcoin(self)
  }

  @IBAction func getBitcoin() {
    delegate?.noTransactionsViewDidSelectGetBitcoin(self)
  }
}

class TransactionHistoryNoBalanceView: NoTransactionsBaseView {
  @IBOutlet var noTransactionsTitle: UILabel! {
    didSet {
      noTransactionsTitle.font = Theme.Font.noTransactionsTitle.font
      noTransactionsTitle.textColor = Theme.Color.grayText.color
      noTransactionsTitle.text = "No Bitcoin...Yet!"
    }
  }
  @IBOutlet var noTransactionsDetail: UILabel! {
    didSet {
      noTransactionsDetail.textColor = Theme.Color.grayText.color
      noTransactionsDetail.font = Theme.Font.noTransactionsDetail.font
      noTransactionsDetail.text = "All incoming and outgoing transactions will appear here."
    }
  }
}

class TransactionHistoryWithBalanceView: NoTransactionsBaseView {
  @IBOutlet var spendBitcoinButton: PrimaryActionButton! {
    didSet {
      spendBitcoinButton.setTitle("SPEND BITCOIN", for: .normal)
      spendBitcoinButton.mode = .spendBitcoin
    }
  }

  @IBAction func spendBitcoin() {
    delegate?.noTransactionsViewDidSelectSpendBitcoin(self)
  }

}
