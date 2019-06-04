//
//  ChangeRemoveVerificationButton.swift
//  DropBit
//
//  Created by BJ Miller on 5/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class ChangeRemoveVerificationButton: UIButton {
  override func awakeFromNib() {
    super.awakeFromNib()
    setTitleColor(Theme.Color.red.color, for: .normal)
    titleLabel?.font = CKFont.medium(14)
  }
}
