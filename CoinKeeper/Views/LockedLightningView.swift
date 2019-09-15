//
//  LockedLightningView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol LockedLightningViewDelegate: class {
  func viewDidAskToUnlockLightning()
}

class LockedLightningView: UIView {

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var dropbitDescriptionLabel: UILabel!
  @IBOutlet var twitterDescriptionLabel: UILabel!
  @IBOutlet var twitterButton: PrimaryActionButton!
  @IBOutlet var backgroundView: LightningUpgradeGradientOverlayView!
  
  weak var delegate: LockedLightningViewDelegate?

  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    titleLabel.font = .medium(17)
    titleLabel.textColor = .white

    dropbitDescriptionLabel.font = .medium(14)
    dropbitDescriptionLabel.textColor = .white

    twitterDescriptionLabel.font = .medium(14)
    twitterDescriptionLabel.textColor = .white
  }

  @IBAction func twitterButtonWasTouched() {
    delegate?.viewDidAskToUnlockLightning()
  }

}
