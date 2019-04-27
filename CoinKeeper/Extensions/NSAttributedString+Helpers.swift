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

  convenience init(image: UIImage, fontDescender descender: CGFloat, imageSize size: CGSize = CGSize(width: 20, height: 20)) {
    let textAttribute = NSTextAttachment()
    textAttribute.image = image
    textAttribute.bounds = CGRect(
      x: 0,
      y: descender, //(-size.height / (size.height / 3)),
      width: size.width,
      height: size.height
    )
    self.init(attachment: textAttribute)
  }
}
