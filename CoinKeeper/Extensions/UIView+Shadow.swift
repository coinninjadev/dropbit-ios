//
//  UIView+Shadow.swift
//  DropBit
//
//  Created by Mitch on 10/31/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension UIView {

  func addShadowView() {
    let shadowView = UIView(frame: frame)
    shadowView.layer.shadowColor = UIColor.black.cgColor
    shadowView.layer.shadowOffset = CGSize(width: 0, height: 4)
    shadowView.layer.masksToBounds = false

    shadowView.layer.shadowOpacity = 0.3
    shadowView.layer.shadowRadius = 3
    shadowView.layer.shadowPath = UIBezierPath(rect: bounds).cgPath
    shadowView.layer.rasterizationScale = UIScreen.main.scale
    shadowView.layer.shouldRasterize = true

    superview?.insertSubview(shadowView, belowSubview: self)

    if superview == shadowView.superview {
      shadowView.translatesAutoresizingMaskIntoConstraints = false
      shadowView.topAnchor.constraint(equalTo: topAnchor).isActive = true
      shadowView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
      shadowView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
      shadowView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
  }

}
