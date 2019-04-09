//
//  NoTransactionsView.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol NoTransactionsViewDelegate: class {
  func noTransactionsViewDidSelectLearnAboutBitcoin(_ view: NoTransactionsView)
}

class NoTransactionsView: UIView {

  @IBOutlet var noTransactionsTitle: UILabel! {
    didSet {
      noTransactionsTitle.font = Theme.Font.noTransactionsTitle.font
      noTransactionsTitle.textColor = Theme.Color.grayText.color
    }
  }
  @IBOutlet var noTransactionsDetail: UILabel! {
    didSet {
      noTransactionsDetail.textColor = Theme.Color.grayText.color
      noTransactionsDetail.font = Theme.Font.noTransactionsDetail.font
    }
  }
  @IBOutlet var learnAboutBitcoinButton: PrimaryActionButton!

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
    xibSetup()
    backgroundColor = Theme.Color.lightGrayBackground.color
  }

  @IBAction func learnAboutBitcoinButtonWasTapped() {
    delegate?.noTransactionsViewDidSelectLearnAboutBitcoin(self)
  }
}
