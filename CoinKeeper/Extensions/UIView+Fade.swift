//
//  UIView+Fade.swift
//  DropBit
//
//  Created by BJ Miller on 4/2/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIView {

  enum UIViewFadeType {
    case bottom
    case top
    case left
    case right

    case vertical
    case horizontal
  }

  func fade(style: UIViewFadeType = .top, percent: CGFloat = 0.2) {
    let gradientLayer = CAGradientLayer()
    gradientLayer.frame = bounds
    gradientLayer.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]

    let none: CGFloat = 0.0
    let all: CGFloat = 1.0
    let half: CGFloat = 0.5

    let start = percent
    let end = 1 - percent

    switch style {
    case .bottom:
      gradientLayer.startPoint = CGPoint(x: half, y: end)
      gradientLayer.endPoint = CGPoint(x: half, y: all)
    case .top:
      gradientLayer.startPoint = CGPoint(x: half, y: start)
      gradientLayer.endPoint = CGPoint(x: half, y: none)
    case .vertical:
      gradientLayer.startPoint = CGPoint(x: half, y: none)
      gradientLayer.endPoint = CGPoint(x: half, y: all)
      gradientLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
      gradientLayer.locations = [none, start, end, all].map { NSNumber(value: Float($0)) }

    case .left:
      gradientLayer.startPoint = CGPoint(x: start, y: half)
      gradientLayer.endPoint = CGPoint(x: none, y: half)
    case .right:
      gradientLayer.startPoint = CGPoint(x: end, y: half)
      gradientLayer.endPoint = CGPoint(x: 1, y: half)
    case .horizontal:
      gradientLayer.startPoint = CGPoint(x: none, y: half)
      gradientLayer.endPoint = CGPoint(x: all, y: half)
      gradientLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
      gradientLayer.locations = [none, start, end, all].map { NSNumber(value: Float($0)) }
    }

    layer.mask = gradientLayer
  }

}
