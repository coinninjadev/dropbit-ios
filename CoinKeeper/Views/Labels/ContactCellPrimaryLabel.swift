//
//  ContactCellPrimaryLabel.swift
//  DropBit
//
//  Created by BJ Miller on 5/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class ContactCellPrimaryLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    font = CKFont.medium(15)
    textColor = Theme.Color.darkBlueText.color
  }
}
