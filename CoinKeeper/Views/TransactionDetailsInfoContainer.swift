//
//  TransactionDetailsInfoContainer.swift
//  CoinKeeper
//
//  Created by Ben Winters on 7/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionDetailsInfoContainer: UIView {

  override func awakeFromNib() {
    super.awakeFromNib()

    setCornerRadius(9)
    backgroundColor = Theme.Color.extraLightGrayBackground.color
    layer.borderWidth = 1
    layer.borderColor = Theme.Color.lightGrayOutline.color.cgColor
  }

}
