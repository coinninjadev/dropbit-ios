//
//  VerfiedTwitterUserIndicatorView.swift
//  DropBit
//
//  Created by BJ Miller on 5/31/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class VerfiedTwitterUserIndicatorView: UIView {

  @IBOutlet var checkmarkImageView: UIImageView!
  @IBOutlet var coloredBackgroundView: UIView!

  override func awakeFromNib() {
    super.awakeFromNib()
    xibSetup()
    backgroundColor = .clear
    coloredBackgroundView.backgroundColor = .lightBlueTint
    let radius = coloredBackgroundView.frame.width / 2.0
    coloredBackgroundView.applyCornerRadius(radius)
  }
}
