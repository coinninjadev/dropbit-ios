//
//  LockedLightningView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class LockedLightningView: UIView {

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var containerView: UIView!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var descriptionTitle: UILabel!
  @IBOutlet var descriptionLabel: UILabel!
  @IBOutlet var backgroundView: LightningUpgradeGradientOverlayView!

  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
    initialize()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
    initialize()
  }

  private func initialize() {
    applyCornerRadius(15, toCorners: .top)
    containerView.applyCornerRadius(5)

    descriptionTitle.font = .semiBold(19)
    descriptionTitle.textColor = .neonGreen

    titleLabel.font = .semiBold(19)
    titleLabel.textColor = .white

    detailLabel.font = .regular(14)
    detailLabel.textColor = .white

    descriptionLabel.font = .medium(14)
    descriptionLabel.textColor = .white
  }

}
