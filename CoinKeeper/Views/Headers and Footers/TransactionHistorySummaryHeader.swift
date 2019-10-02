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
    case .backUpWallet: return "Don't forget to backup your wallet"
    }
  }
}

protocol TransactionHistorySummaryHeaderDelegate: AnyObject {
  func didTapSummaryHeader(_ header: TransactionHistorySummaryHeader)
}

class TransactionHistorySummaryHeader: UICollectionReusableView {

  private weak var delegate: TransactionHistorySummaryHeaderDelegate!

  @IBOutlet var messageLabel: UILabel! // use messageLabel instead of button.titleLabel so that arrow can be constrained to the text
  @IBOutlet var messageButton: UIButton!
  @IBOutlet var bottomConstraint: NSLayoutConstraint!

  @IBAction func performAction(_ sender: Any) {
    delegate.didTapSummaryHeader(self)
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    self.backgroundColor = .clear
    messageLabel.font = .regular(14)
    messageLabel.textColor = .whiteText
    messageButton.backgroundColor = .warning
  }

  func configure(with message: String, delegate: TransactionHistorySummaryHeaderDelegate) {
    messageLabel.text = message
    self.delegate = delegate
  }

}
