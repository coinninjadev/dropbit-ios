//
//  SummaryCellSatsLabel.swift
//  DropBit
//
//  Created by Ben Winters on 8/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SummaryCellSatsLabel: UILabel {

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  private func initialize() {
    self.textColor = .bitcoinOrange
    self.font = .semiBold(13)

    self.translatesAutoresizingMaskIntoConstraints = false
    self.heightAnchor.constraint(equalToConstant: 28).isActive = true
  }

}
