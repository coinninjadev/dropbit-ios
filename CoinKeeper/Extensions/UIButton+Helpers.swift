//
//  UIButton+Helpers.swift
//  DropBit
//
//  Created by Ben Winters on 6/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIButton {

  /// Pass nil for widthConstraint to skip resizing the button
  func configure(withTitle title: String,
                 font: UIFont,
                 foregroundColor: UIColor,
                 imageName: String,
                 imageSize: CGSize,
                 titleEdgeInsets: UIEdgeInsets,
                 contentEdgeInsets: UIEdgeInsets) {

    contentHorizontalAlignment = .fill
    contentVerticalAlignment = .fill
    imageView?.contentMode = .scaleAspectFit

    self.titleEdgeInsets = titleEdgeInsets
    self.contentEdgeInsets = contentEdgeInsets

    let image = UIImage(imageLiteralResourceName: imageName)
    setImage(image, for: .normal)
    setImage(image, for: .highlighted)
    setImageSize(imageSize)

    tintColor = foregroundColor //sets the image mask color

    titleLabel?.font = font
    setTitle(title, for: .normal)
    setTitle(title, for: .highlighted)
    setTitleColor(foregroundColor, for: .normal)
    setTitleColor(foregroundColor, for: .highlighted)
  }

  private func setImageSize(_ imageSize: CGSize) {
    let vPadding = contentEdgeInsets.top + contentEdgeInsets.bottom
    let defaultImageHeight = self.frame.height - vPadding
    let vInset = (defaultImageHeight - imageSize.height) / 2
    var hInset: CGFloat = 0

    let minHPadding: CGFloat = 4
    if vInset < minHPadding {
      hInset = minHPadding
    }

    self.imageEdgeInsets = UIEdgeInsets(top: vInset, left: hInset, bottom: vInset, right: -hInset)
  }

  func styleAddButtonWith(title: String) {
    setTitleColor(.darkGrayText, for: .normal)
    titleLabel?.font = .regular(15)
    setTitle("  " + title, for: .normal)
    let plusImage = UIImage(imageLiteralResourceName: "plusIcon").withRenderingMode(.alwaysTemplate)
    setImage(plusImage, for: .normal)
    tintColor = .darkGrayText
  }

}
