//
//  SummaryCellPillLabel.swift
//  DropBit
//
//  Created by Ben Winters on 8/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SummaryCellPillLabel: UILabel {

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  override func drawText(in rect: CGRect) {
    let insets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    super.drawText(in: rect.inset(by: insets))
  }

  private func initialize() {
    self.translatesAutoresizingMaskIntoConstraints = false
    applyCornerRadius(frame.height / 2)
    self.heightAnchor.constraint(equalToConstant: 28).isActive = true

    self.textAlignment = .center
    self.textColor = .lightGrayText
  }

  /// `isAmount` true if text is transaction amount, false if text is transaction status
  func configure(withText text: String, backgroundColor: UIColor, isAmount: Bool) {
    self.text = text
    self.backgroundColor = backgroundColor
    self.font = isAmount ? .regular(15) : .regular(14)
  }

}
