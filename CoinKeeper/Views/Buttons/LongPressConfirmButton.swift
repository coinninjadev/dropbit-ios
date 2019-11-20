//
//  LongPressConfirmButton.swift
//  DropBit
//
//  Created by Mitchell on 4/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol LongPressConfirmButtonDelegate: class {
  func confirmationButtonDidConfirm(_ button: LongPressConfirmButton)
}

struct ConfirmButtonConfig {

  let foregroundColor: UIColor
  var backgroundColor: UIColor = .darkGrayBackground
  let secondsToConfirm: Double

  static var original: ConfirmButtonConfig {
    ConfirmButtonConfig(foregroundColor: .lightBlueTint, secondsToConfirm: 3.0)
  }

  static var onChain: ConfirmButtonConfig {
    ConfirmButtonConfig(foregroundColor: .bitcoinOrange, secondsToConfirm: 3.0)
  }

  static var lightning: ConfirmButtonConfig {
    ConfirmButtonConfig(foregroundColor: .lightningBlue, secondsToConfirm: 1.5)
  }

}

class LongPressConfirmButton: UIButton {

  weak var delegate: LongPressConfirmButtonDelegate?

  private var backgroundBezierPath: UIBezierPath = UIBezierPath()
  private var backgroundShapeLayer: CAShapeLayer = CAShapeLayer()
  private var foregroundShapeLayer: CAShapeLayer = CAShapeLayer()
  private var circleAnimation: CABasicAnimation = CABasicAnimation()

  private var feedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
  lazy private var longPressGestureRecognizer: UILongPressGestureRecognizer =
    UILongPressGestureRecognizer(target: self, action: #selector(confirmButtonDidConfirm))

  func configure(with config: ConfirmButtonConfig, delegate: LongPressConfirmButtonDelegate?) {
    foregroundShapeLayer.strokeColor = config.foregroundColor.cgColor
    backgroundShapeLayer.strokeColor = config.backgroundColor.cgColor
    circleAnimation.duration = config.secondsToConfirm
    longPressGestureRecognizer.minimumPressDuration = config.secondsToConfirm
    self.delegate = delegate
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initalize()
  }

  private func initalize() {
    setupLines()
    setupDefaults()
    setupCircleAnimation()

    configure(with: .original, delegate: nil)
    feedbackGenerator.prepare()
    longPressGestureRecognizer.allowableMovement = 1000
    self.addGestureRecognizer(longPressGestureRecognizer)
    self.addTarget(self, action: #selector(tapDidBegin), for: .touchDown)
    self.addTarget(self, action: #selector(tapDidEnd), for: .touchUpInside)
    self.addTarget(self, action: #selector(tapDidEnd), for: .touchUpOutside)
  }

  @objc func confirmButtonDidConfirm() {
    if longPressGestureRecognizer.state == .began {
      delegate?.confirmationButtonDidConfirm(self)
    }

    reset()
  }

  @objc func tapDidBegin() {
    feedbackGenerator.impactOccurred()
    animate()
  }

  @objc func tapDidEnd() {
    reset()
  }

  private func animate() {
    startAnimation()
  }

  private func reset() {
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
