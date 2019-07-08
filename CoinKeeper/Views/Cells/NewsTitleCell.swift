//
//  NewsTitleCell.swift
//  DropBit
//
//  Created by Mitchell Malleo on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class NewsTitleCell: UITableViewCell {
  @IBOutlet var titleLabel: UILabel! {
    didSet {
      titleLabel.font = .semiBold(22)
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .lightGrayBackground
    isUserInteractionEnabled = false
  }
}
