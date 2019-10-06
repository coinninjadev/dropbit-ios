//
//  TitleDetailView.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

struct TitleDetailViewStyleConfig {
  let titleFont: UIFont
  let titleColor: UIColor
  let detailFont: UIFont
  let detailColor: UIColor

  init(titleFont: UIFont, titleColor: UIColor,
       detailFont: UIFont, detailColor: UIColor) {
    self.titleFont = titleFont
    self.titleColor = titleColor
    self.detailFont = detailFont
    self.detailColor = detailColor
  }

  init(font: UIFont, color: UIColor) {
    self.init(titleFont: font, titleColor: color, detailFont: font, detailColor: color)
  }

}

class TitleDetailView: UIView {

  let titleLabel = UILabel()
  let detailLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupConstraints()
  }

  convenience init(title: String, detail: String, style: TitleDetailViewStyleConfig) {
    self.init(frame: .zero)
    titleLabel.text = title
    detailLabel.text = detail
    titleLabel.font = style.titleFont
    detailLabel.font = style.detailFont
    titleLabel.textColor = style.titleColor
    detailLabel.textColor = style.detailColor
    titleLabel.textAlignment = .left
    detailLabel.textAlignment = .right
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  private func setupConstraints() {
    self.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.setContentHuggingPriority(.required, for: .horizontal)
    titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    self.addSubview(titleLabel)
    self.addSubview(detailLabel)
    titleLabel.constrain(to: self, trailingConstant: nil)
    detailLabel.constrain(to: self, leadingConstant: nil)
    NSLayoutConstraint.activate([
      titleLabel.trailingAnchor.constraint(equalTo: detailLabel.leadingAnchor, constant: 8)
    ])
  }

}
