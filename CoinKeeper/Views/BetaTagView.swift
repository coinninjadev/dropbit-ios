//
//  BetaTagView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class BetaTagView: UIView {

  @IBOutlet var betaLabel: UILabel!

  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    applyCornerRadius(2)
    betaLabel.font = .medium(8)
    betaLabel.textColor = .white
    backgroundColor = .neonGreen
  }
}
