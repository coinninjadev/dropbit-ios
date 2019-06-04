//
//  SettingsCellTitleLabel.swift
//  DropBit
//
//  Created by BJ Miller on 5/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SettingsCellTitleLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = CKFont.light(13)
    textColor = .darkBlueText
  }
}
