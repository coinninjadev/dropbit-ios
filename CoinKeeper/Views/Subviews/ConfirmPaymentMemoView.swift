//
//  ConfirmPaymentMemoView.swift
//  DropBit
//
//  Created by Ben Winters on 1/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

typealias DetailCellMemoConfig = ConfirmPaymentMemoViewConfig
struct ConfirmPaymentMemoViewConfig {
  let memo: String
  let isShared: Bool
  let isSent: Bool
  let isIncoming: Bool
  let recipientName: String?
}

class ConfirmPaymentMemoView: UIView {

  @IBOutlet var topBackgroundView: UIView!
  @IBOutlet var bottomBackgroundView: UIView!
  @IBOutlet var memoLabel: UILabel!
  @IBOutlet var separatorView: UIView!
  @IBOutlet var sharedStatusImage: UIImageView!
  @IBOutlet var sharedStatusLabel: UILabel!

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .clear
    self.applyCornerRadius(6)
    self.layer.borderWidth = 1
    self.layer.borderColor = UIColor.mediumGrayBorder.cgColor
    separatorView.backgroundColor = .mediumGrayBorder

    topBackgroundView.backgroundColor = .lightGrayBackground
    bottomBackgroundView.backgroundColor = .whiteBackground

    memoLabel.textAlignment = .center
    memoLabel.textColor = .darkBlueText
    memoLabel.font = .regular(14)

    sharedStatusLabel.textColor = .darkGrayText
    sharedStatusLabel.font = .regular(10)
  }

  /// This view as a whole should be hidden if no memo. `isSent` determines past/future tense.
  func configure(with config: ConfirmPaymentMemoViewConfig) {
    memoLabel.text = config.memo
    sharedStatusImage.image = config.isShared ? isSharedImage : isNotSharedImage

    if config.isShared {
      sharedStatusLabel.text = isSharedDescription(for: config)
    } else {
      let prefix = config.isSent ? "Seen" : "Will be seen"
      sharedStatusLabel.text = "\(prefix) by only you"
    }
  }

  private func isSharedDescription(for config: ConfirmPaymentMemoViewConfig) -> String {
    if config.isIncoming {
       return "Memo from sender"
    } else {
      return "Shared memo"
    }
  }

  var isSharedImage: UIImage? { return UIImage(named: "sharedMemoPeople") }
  var isNotSharedImage: UIImage? { return UIImage(named: "sharedMemoPerson") }

}
