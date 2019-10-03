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
    applyCornerRadius(5.0)
  }

  func load(with userIdentityType: UserIdentityType, identityString: String) {
    self.userIdentityType = userIdentityType
    switch userIdentityType {
    case .phone:
      decorationBackgroundView.backgroundColor = .darkBlueBackground
      decorationImageView.image = UIImage(imageLiteralResourceName: "phoneDrawerIcon")
    case .twitter:
      decorationBackgroundView.backgroundColor = .lightBlueTint
      decorationImageView.image = UIImage(imageLiteralResourceName: "twitterBird")
    }

    identityLabel.text = identityString
    identityLabel.textColor = .darkBlueText
    identityLabel.font = .light(18)

    verificationStatusLabel.textColor = .appleGreen
    verificationStatusLabel.font = .secondaryButtonTitle
    verificationStatusLabel.text = "Verified"
  }
}
