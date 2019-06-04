//
//  SettingsTitleLabel.swift
//  DropBit
//
//  Created by BJ Miller on 5/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SettingsTitleLabel: UILabel {

  override func awakeFromNib() {
    super.awakeFromNib()
    font = CKFont.regular(15)
    textColor = .darkBlueText
  }

}
