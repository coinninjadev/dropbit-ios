//
//  ToggleLightningTitleView.swift
//  DropBit
//
//  Created by Ben Winters on 7/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class WalletToggleTitleView: UIView {

  var iconView: UIImageView!
  var titleLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.translatesAutoresizingMaskIntoConstraints = false
  }

  func setupConstraints(iconSize: CGSize, horizontalSpacing: CGFloat) {
    iconView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(iconView)

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(titleLabel)

    NSLayoutConstraint.activate([
      iconView.widthAnchor.constraint(equalToConstant: iconSize.width),
      iconView.heightAnchor.constraint(equalToConstant: iconSize.height),
      iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
      iconView.topAnchor.constraint(equalTo: self.topAnchor),
      iconView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
      titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: horizontalSpacing),
      titleLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
      titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor)
      ]
    )
  }
}

class ToggleLightningTitleView: WalletToggleTitleView {

  override init(frame: CGRect) {
    super.init(frame: frame)

    iconView = UIImageView(image: UIImage(named: "walletToggleLightning"))
    titleLabel = WalletToggleTitleLabel(frame: .zero, text: "Lightning")
    setupConstraints(iconSize: CGSize(width: 12, height: 18), horizontalSpacing: 6)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

}

class ToggleBitcoinTitleView: WalletToggleTitleView {

  override init(frame: CGRect) {
    super.init(frame: frame)

    iconView = UIImageView(image: UIImage(named: "walletToggleBitcoin"))
    titleLabel = WalletToggleTitleLabel(frame: .zero, text: "Bitcoin")
    setupConstraints(iconSize: CGSize(width: 11, height: 18), horizontalSpacing: 10)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

}
