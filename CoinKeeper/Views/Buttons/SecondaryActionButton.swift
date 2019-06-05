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
    setTitleColor(.darkBlueBackground, for: .normal)
    titleLabel?.font = .secondaryButtonTitle
  }

}
