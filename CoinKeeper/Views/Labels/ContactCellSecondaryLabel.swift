//
//  ContactCellSecondaryLabel.swift
//  DropBit
//
//  Created by BJ Miller on 5/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class ContactCellSecondaryLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    textColor = Theme.Color.grayText.color
    font = CKFont.light(13)
  }
}
