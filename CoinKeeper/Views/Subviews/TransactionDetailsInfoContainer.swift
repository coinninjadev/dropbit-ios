//
//  TransactionDetailsInfoContainer.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionDetailsInfoContainer: UIView {

  override func awakeFromNib() {
    super.awakeFromNib()

    applyCornerRadius(9)
    backgroundColor = .extraLightGrayBackground
    layer.borderWidth = 1
    layer.borderColor = UIColor.mediumGrayBorder.cgColor
  }

}
