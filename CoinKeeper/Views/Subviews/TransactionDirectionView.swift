//
//  TransactionDirectionView.swift
//  DropBit
//
//  Created by Ben Winters on 8/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TransactionDirectionView: UIView {

  private weak var iconImageView: UIImageView?

  var image: UIImage? {
    return iconImageView?.image
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  private func initialize() {
    let imageView = UIImageView(image: nil)
    iconImageView = imageView
    iconImageView?.contentMode = .center
    iconImageView?.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(imageView)
    imageView.constrain(to: self)

    let radius = self.frame.width / 2
    self.applyCornerRadius(radius)
  }

  /// `logoBackgroundColor` is used for the small circle behind the Twitter bird
  func configure(image: UIImage, bgColor: UIColor) {
    iconImageView?.image = image
    backgroundColor = bgColor
  }

}
