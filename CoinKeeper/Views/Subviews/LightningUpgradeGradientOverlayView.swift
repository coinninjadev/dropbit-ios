//
//  LightningUpgradeGradientOverlayView.swift
//  DropBit
//
//  Created by BJ Miller on 9/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class LightningUpgradeGradientOverlayView: UIView {

  override func awakeFromNib() {
    super.awakeFromNib()

    applyCornerRadius(15)

    let gradient = CAGradientLayer()
    gradient.frame = self.bounds
    gradient.colors = [UIColor.mediumPurple.cgColor, UIColor.darkPurple.cgColor]
    self.layer.addSublayer(gradient)
  }

}
