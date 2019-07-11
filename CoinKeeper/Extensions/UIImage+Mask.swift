//
//  UIImage+Mask.swift
//  CoinKeeper
//
//  Created by Ben Winters on 7/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIImage {
  public func maskWithColor(color: UIColor) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { _ in
      let rect = CGRect(origin: CGPoint.zero, size: size)

      color.setFill()
      self.draw(in: rect)

      UIRectFillUsingBlendMode(rect, .sourceIn)
    }
    return image
  }
}
