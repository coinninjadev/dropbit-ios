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
    let renderer = UIGraphicsImageRenderer(size: layer.frame.size)
    image = renderer.image { layer.render(in: $0.cgContext) }
    return image
  }
}
