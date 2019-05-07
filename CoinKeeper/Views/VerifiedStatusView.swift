//
//  VerifiedStatusView.swift
//  DropBit
//
//  Created by BJ Miller on 5/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class VerifiedStatusView: UIView {

  var userIdentityType: UserIdentityType = .phone

  @IBOutlet var decorationBackgroundView: UIView!
  @IBOutlet var decorationImageView: UIImageView!
  @IBOutlet var identityLabel: UILabel!
  @IBOutlet var verificationStatusLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    xibSetup()
  }

  func load(with userIdentityType: UserIdentityType, identityString: String) {
    self.userIdentityType = userIdentityType
    switch userIdentityType {
    case .phone: decorationBackgroundView.backgroundColor = Theme.Color.darkBlueButton.color
    case .twitter: decorationBackgroundView.backgroundColor = Theme.Color.lightBlueTint.color
    }

    identityLabel.text = identityString
    identityLabel.textColor = Theme.Color.darkBlueText.color
    identityLabel.font = Theme.Font.verificationIdentity.font

    verificationStatusLabel.textColor = Theme.Color.appleGreen.color
    verificationStatusLabel.font = Theme.Font.secondaryButtonTitle.font
    verificationStatusLabel.text = "Verified"
  }
}
