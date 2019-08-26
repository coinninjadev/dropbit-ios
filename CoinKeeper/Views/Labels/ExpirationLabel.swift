//
//  ExpirationLabel.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/26/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class ExpirationLabel: UILabel {

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .darkRed
    textColor = .white
    font = .regular(13)
    text = "expires in 24 hours"
    layer.cornerRadius = 14
    clipsToBounds = true
  }
}
