//
//  NSAttributedString+Helpers.swift
//  DropBit
//
//  Created by Mitch on 1/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension NSAttributedString {
  static func + (left: NSAttributedString, right: NSAttributedString) -> NSAttributedString {
    let result = NSMutableAttributedString()
    result.append(left)
    result.append(right)
    return result
  }

  static func + (left: NSAttributedString, right: String) -> NSAttributedString {
    let rightAttributedString = NSAttributedString(string: right)

    let result = NSMutableAttributedString()
    result.append(left)
    result.append(rightAttributedString)
    return result
  }

  convenience init(image: UIImage,
                   fontDescender: CGFloat,
                   imageSize: CGSize = CGSize(width: 20, height: 20)) {
    let textAttribute = NSTextAttachment()
    textAttribute.image = image
    textAttribute.bounds = CGRect(
      x: 0,
      y: fontDescender, //(-size.height / (size.height / 3)),
      width: imageSize.width,
      height: imageSize.height
    )
    self.init(attachment: textAttribute)
  }

  convenience init(imageName: String,
                   imageSize: CGSize = CGSize(width: 20, height: 20),
                   title: String,
                   textColor: UIColor,
                   font: UIFont) {

    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: textColor
    ]

    let image = UIImage(imageLiteralResourceName: imageName)
    let attributedImage = NSAttributedString(image: image,
                                            fontDescender: font.descender,
                                            imageSize: imageSize)
    let attributedText = NSAttributedString(string: "  \(title)", attributes: attributes)
    self.init(attributedString: attributedImage + attributedText)
  }

}
