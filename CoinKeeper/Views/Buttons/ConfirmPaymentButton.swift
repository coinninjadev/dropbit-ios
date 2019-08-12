//
//  ConfirmPaymentButton.swift
//  CoinKeeper
//
//  Created by Mitchell on 4/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol ConfirmPaymentButtonDelegate: class {
  func didConfirm()
}

class ConfirmPaymentButton: UIButton {

  enum Style {
    case original
    case onChain
    case lightning
  }

  private var backgroundBezierPath: UIBezierPath = UIBezierPath()
  private var backgroundShapeLayer: CAShapeLayer = CAShapeLayer()
  private var foregroundShapeLayer: CAShapeLayer = CAShapeLayer()
  private var circleAnimation: CABasicAnimation = CABasicAnimation()
  private var longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer()

  var secondsToConfirm: Double = 3.0
  var style: Style = .original {
    didSet {
      switch style {
      case .original:
        foregroundShapeLayer.strokeColor = UIColor.lightBlueTint.cgColor
      case .onChain:
        foregroundShapeLayer.strokeColor = UIColor.bitcoinOrange.cgColor
      case .lightning:
        foregroundShapeLayer.strokeColor = UIColor.lightningBlue.cgColor
      }
    }
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initalize()
  }

  private func initalize() {
    setupLines()
    setupDefaults()
    setupCircleAnimation()
  }

  func animate() {
    startAnimation()
  }

  func reset() {
    foregroundShapeLayer.removeAllAnimations()
    foregroundShapeLayer.strokeEnd = 0.0
    backgroundShapeLayer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
    foregroundShapeLayer.transform = CATransform3DMakeScale(1.0, 1.0, 1.0)
  }

  private func setupDefaults() {
    backgroundColor = UIColor.clear
  }

  private func setupCircleAnimation() {
    circleAnimation = CABasicAnimation(keyPath: "strokeEnd")
    circleAnimation.duration = secondsToConfirm
    circleAnimation.repeatCount = 1.0
    circleAnimation.fromValue = 0.0
    circleAnimation.toValue = 1.0
    circleAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
  }

  private func startAnimation() {
    foregroundShapeLayer.add(circleAnimation, forKey: "draw")
    let scale: CGFloat = 1.5
    backgroundShapeLayer.transform = CATransform3DMakeScale(scale, scale, 1.0)
    foregroundShapeLayer.transform = CATransform3DMakeScale(scale, scale, 1.0)
  }

  private func setupLines() {
    backgroundBezierPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0,
                                                            width: frame.size.width,
                                                            height: frame.size.height),
                                        byRoundingCorners: .allCorners,
                                        cornerRadii: CGSize(width: frame.size.width / 2.0, height: frame.size.height / 2.0))

    let lineWidthDivisor: CGFloat = 12.0

    backgroundShapeLayer.path = backgroundBezierPath.cgPath
    backgroundShapeLayer.lineCap = CAShapeLayerLineCap.round
    backgroundShapeLayer.lineWidth = frame.size.height / lineWidthDivisor
    backgroundShapeLayer.strokeColor = UIColor.darkGrayText.cgColor
    backgroundShapeLayer.fillColor = UIColor.clear.cgColor
    backgroundShapeLayer.strokeEnd = 1.0
    backgroundShapeLayer.zPosition = -1
    backgroundShapeLayer.bounds = bounds
    backgroundShapeLayer.frame = bounds

    foregroundShapeLayer.path = backgroundBezierPath.cgPath
    foregroundShapeLayer.lineCap = CAShapeLayerLineCap.round
    foregroundShapeLayer.fillColor = UIColor.clear.cgColor
    foregroundShapeLayer.lineWidth = frame.size.height / lineWidthDivisor
    foregroundShapeLayer.speed = 1.0
    foregroundShapeLayer.timeOffset = 0.0
    foregroundShapeLayer.beginTime = 0.0
    foregroundShapeLayer.strokeEnd = 0.0
    foregroundShapeLayer.bounds = bounds
    foregroundShapeLayer.frame = bounds

    layer.addSublayer(backgroundShapeLayer)
    layer.addSublayer(foregroundShapeLayer)
  }
}
