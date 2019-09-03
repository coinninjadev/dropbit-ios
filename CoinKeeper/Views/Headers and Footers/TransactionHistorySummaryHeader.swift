//
//  TransactionHistorySummaryHeader.swift
//  DropBit
//
//  Created by Ben Winters on 9/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

enum SummaryHeaderType {
  case backUpWallet

  var message: String {
    switch self {
    case .backUpWallet: return "Back Up Your Wallet"
    }
  }
}

protocol TransactionHistorySummaryHeaderDelegate: AnyObject {
  func didTapSummaryHeader(_ header: TransactionHistorySummaryHeader)
}

class TransactionHistorySummaryHeader: UICollectionReusableView {

  private weak var delegate: TransactionHistorySummaryHeaderDelegate!

  @IBOutlet var messageButton: UIButton!
  @IBOutlet var bottomConstraint: NSLayoutConstraint!

  @IBAction func performAction(_ sender: Any) {
    delegate.didTapSummaryHeader(self)
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundColor = .clear
    messageButton.titleLabel?.font = .medium(16)
    messageButton.setTitleColor(.whiteText, for: .normal)
    messageButton.setTitleColor(.whiteText, for: .highlighted)
    messageButton.backgroundColor = .warningHeader
  }

  func configure(with message: String, delegate: TransactionHistorySummaryHeaderDelegate) {
    messageButton.setTitle(message, for: .normal)
    messageButton.setTitle(message, for: .highlighted)
    self.delegate = delegate
  }

}
