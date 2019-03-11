//
//  UIApplication+Screenshot.swift
//  DropBit
//
//  Created by BJ Miller on 11/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIApplication {
  func screenshot() -> UIImage? {
    var image: UIImage?
    guard let layer = UIApplication.shared.keyWindow?.layer else { return nil }
    let scale = UIScreen.main.scale
    UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    layer.render(in: context)
    image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }
}
