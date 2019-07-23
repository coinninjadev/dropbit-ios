//
//  WalletToggleTitleLabel.swift
//  DropBit
//
//  Created by Ben Winters on 7/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class WalletToggleTitleLabel: UILabel {

  init(frame: CGRect, text: String) {
    super.init(frame: frame)
    self.text = text
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    textColor = .whiteText
    font = .medium(14)
  }

}
