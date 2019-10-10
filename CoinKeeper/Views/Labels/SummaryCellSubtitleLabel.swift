//
//  SummaryCellSubtitleLabel.swift
//  DropBit
//
//  Created by Ben Winters on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SummaryCellSubtitleLabel: UILabel {
  override func awakeFromNib() {
    super.awakeFromNib()
    textColor = .darkBlueText
    numberOfLines = 1
    textAlignment = .left
  }
}
