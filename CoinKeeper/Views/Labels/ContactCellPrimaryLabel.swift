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
    font = Theme.Font.contactTitle.font
    textColor = Theme.Color.darkBlueText.color
  }
}
