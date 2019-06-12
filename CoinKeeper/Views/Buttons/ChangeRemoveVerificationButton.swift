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
    setTitleColor(.darkPeach, for: .normal)
    titleLabel?.font = .medium(14)
  }
}
