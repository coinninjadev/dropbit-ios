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

    UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
    let context = UIGraphicsGetCurrentContext()!

    let rect = CGRect(origin: CGPoint.zero, size: size)

    color.setFill()
    self.draw(in: rect)

    context.setBlendMode(.sourceIn)
    context.fill(rect)

    let resultImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return resultImage
  }

}
