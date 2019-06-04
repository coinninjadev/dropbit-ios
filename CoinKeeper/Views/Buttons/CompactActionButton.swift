//
//  CompactActionButton.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class CompactActionButton: PrimaryActionButton {

  override func awakeFromNib() {
    super.awakeFromNib()
    titleLabel?.font = CKFont.compactButtonTitle
  }

}
