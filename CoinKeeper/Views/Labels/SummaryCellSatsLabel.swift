//
//  SummaryCellSatsLabel.swift
//  DropBit
//
//  Created by Ben Winters on 8/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SummaryCellBitcoinLabel: UILabel {
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  private let horizontalInset: CGFloat = 8
  private let fontReference: UIFont = .semiBold(13)

  override var intrinsicContentSize: CGSize {
    let buffer = CGFloat(horizontalInset)
    var size = super.intrinsicContentSize
    size.width += buffer
    return size
  }

  fileprivate func initialize() {
    self.backgroundColor = .clear
    self.textColor = .bitcoinOrange
    self.font = fontReference
    self.textAlignment = .right

    self.translatesAutoresizingMaskIntoConstraints = false
    self.numberOfLines = 1
    self.heightAnchor.constraint(equalToConstant: 28).isActive = true
  }

  func configure(withAttributedText attributedText: NSAttributedString?) {
    self.attributedText = attributedText
    guard let attr = attributedText else { return }
    var attributes: StringAttributes = attr.attributes(at: 0, effectiveRange: nil)
    attributes[.font] = fontReference
    let textWidth = attr.string.size(withAttributes: attributes).width + horizontalInset
    self.widthAnchor.constraint(equalToConstant: textWidth).isActive = true
  }

}

class SummaryCellSatsLabel: SummaryCellBitcoinLabel {

}
