//
//  ConfirmPaymentMemoView.swift
//  DropBit
//
//  Created by Ben Winters on 1/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class ConfirmPaymentMemoView: UIView {

  @IBOutlet var topBackgroundView: UIView!
  @IBOutlet var bottomBackgroundView: UIView!
  @IBOutlet var memoLabel: UILabel!
  @IBOutlet var separatorView: UIView!
  @IBOutlet var sharedStatusImage: UIImageView!
  @IBOutlet var isSharedDescriptionLabel: UILabel!

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
    self.layer.borderColor = UIColor.lightGrayOutline.cgColor
    separatorView.backgroundColor = .lightGrayOutline

    topBackgroundView.backgroundColor = .lightGrayBackground
    bottomBackgroundView.backgroundColor = .whiteBackground

    memoLabel.textAlignment = .center
    memoLabel.textColor = .darkBlueText
    memoLabel.font = .regular(14)

    isSharedDescriptionLabel.textColor = .grayText
    isSharedDescriptionLabel.font = .regular(10)
  }

  /// This view as a whole should be hidden if no memo. `isSent` determines past/future tense.
  func configure(memo: String, isShared: Bool, isSent: Bool, isIncoming: Bool, recipientName: String?) {
    memoLabel.text = memo

    if isShared {
      sharedStatusImage.image = UIImage(named: "sharedMemoPeople")

      if isIncoming {
        isSharedDescriptionLabel.text = "Memo from sender"
      } else {
        let prefix = isSent ? "Shared with" : "Will be seen by"
        let recipient = recipientName ?? "the recipient"
        isSharedDescriptionLabel.text = "\(prefix) \(recipient)"
      }
    } else {
      let prefix = isSent ? "Seen" : "Will be seen"
      isSharedDescriptionLabel.text = "\(prefix) by only you"
      sharedStatusImage.image = UIImage(named: "sharedMemoPerson")
    }
  }

}
