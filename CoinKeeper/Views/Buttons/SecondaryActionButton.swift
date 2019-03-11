//
//  SecondaryActionButton.swift
//  DropBit
//
//  Created by BJ Miller on 11/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SecondaryActionButton: UIButton {

  override func awakeFromNib() {
    super.awakeFromNib()
    setTitleColor(Theme.Color.darkBlueButton.color, for: .normal)
    titleLabel?.font = Theme.Font.secondaryButtonTitle.font
  }

}
