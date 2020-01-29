//
//  PillLabel.swift
//  DropBit
//
//  Created by Ben Winters on 8/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class PillLabel: UILabel {

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  let horizontalInset: CGFloat = 12

  override var intrinsicContentSize: CGSize {
    let buffer = CGFloat(horizontalInset)
    var size = super.intrinsicContentSize
    size.width += buffer
    return size
  }

  private func initialize() {
    self.numberOfLines = 1
    self.translatesAutoresizingMaskIntoConstraints = false
    self.heightAnchor.constraint(equalToConstant: frame.height).isActive = true
    self.applyCornerRadius(frame.height / 2)
    self.textAlignment = .center
    self.textColor = .lightGrayText
  }

  /// `isAmount` true if text is transaction amount, false if text is transaction status
  func configure(withText text: String, backgroundColor: UIColor, isAmount: Bool) {
    self.text = text
    self.backgroundColor = backgroundColor
    let configuredFont: UIFont = isAmount ? .regular(15) : .regular(14)
    self.font = configuredFont
    let textWidth = text.size(withAttributes: [.font: configuredFont]).width + (horizontalInset * 2)
    self.widthAnchor.constraint(equalToConstant: textWidth).isActive = true
  }

}
