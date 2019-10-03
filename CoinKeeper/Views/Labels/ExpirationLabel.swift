//
//  ExpirationLabel.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/26/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class ExpirationLabel: PaddedLabel {

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .darkRed
    textColor = .white
    font = .regular(13)
    applyCornerRadius(14)
  }

  func configure(hoursRemaining: Int?) {
    if let hours = hoursRemaining {
      text = "expires in \(hours) hours"
    } else {
      text = "expired"
    }
  }

}
