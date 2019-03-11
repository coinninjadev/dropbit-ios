//
//  UIImageView+GIF.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Gifu
import UIKit

extension UIImageView: GIFAnimatable {
  private struct AssociatedKeys {
    static var AnimatorKey = "gifu.animator.key"
  }

  override open func display(_ layer: CALayer) {
    updateImageIfNeeded()
  }

  public var animator: Animator? {
    get {
      guard let animator = objc_getAssociatedObject(self, &AssociatedKeys.AnimatorKey) as? Animator else {
        let animator = Animator(withDelegate: self)
        self.animator = animator
        return animator
      }

      return animator
    }

    set {
      objc_setAssociatedObject(self, &AssociatedKeys.AnimatorKey, newValue as Animator?, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}

extension UIImage {
  static func data(asset: String) -> Data? {
    if let asset = NSDataAsset(name: asset) {
      return asset.data
    }
    return nil
  }
}
