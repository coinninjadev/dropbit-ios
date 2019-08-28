//
//  SummaryCellPaddedLabelView.swift
//  DropBit
//
//  Created by Ben Winters on 8/28/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SummaryCellPaddedLabelView: UIView {

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  private func initialize() {
    backgroundColor = .clear
    translatesAutoresizingMaskIntoConstraints = false
  }

  convenience init(label: UILabel, padding: CGFloat) {
    self.init(frame: .zero)
    self.addSubview(label)
    label.constrain(to: self, trailingConstant: -padding)
  }

}
