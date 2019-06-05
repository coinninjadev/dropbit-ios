//
//  SuccessFailView.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/1/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SuccessFailView: UIView {

  enum Mode {
    case pending
    case success
    case failure
  }

  enum Animation: String {
    case growCircle
    case spinCircle
  }

  var mode: Mode = .pending {
    didSet {
      reset()
      startAnimation()
    }
  }

  private var backgroundBezierPath: UIBezierPath = UIBezierPath()
  private var backgroundShapeLayer: CAShapeLayer = CAShapeLayer()
  private var foregroundShapeLayer: CAShapeLayer = CAShapeLayer()
  private var circleAnimationGroup: CAAnimationGroup = CAAnimationGroup()

  private var checkmarkBezierPath: UIBezierPath = UIBezierPath()
  private var checkmarkBackgroundShapeLayer: CAShapeLayer = CAShapeLayer()
  private var checkmarkForegroundShapeLayer: CAShapeLayer = CAShapeLayer()

  private var leftTopErrorBezierPath: UIBezierPath = UIBezierPath()
  private var leftBottomErrorBezierPath: UIBezierPath = UIBezierPath()
  private var errorBackgroundShapeLayerLeftTop: CAShapeLayer = CAShapeLayer()
  private var errorForegroundShapeLayerLeftTop: CAShapeLayer = CAShapeLayer()
  private var errorBackgroundShapeLayerLeftBottom: CAShapeLayer = CAShapeLayer()
  private var errorForegroundShapeLayerLeftBottom: CAShapeLayer = CAShapeLayer()

  private let lineWidth: CGFloat = 6.5

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initalize()
  }

  private func initalize() {
    setupLines()
    setupDefaults()
  }

  private func setupLines() {
    setupCircle()
    setupCheckmark()
    setupX()
  }

  private func setupDefaults() {
    backgroundColor = UIColor.clear
  }

  private func startAnimation() {
    switch mode {
    case .pending:
      animateForLoading()
    case .success:
      animateForSuccess()
    case .failure:
      animateForFailure()
    }
  }

  let checkmarkAnimation: CABasicAnimation = {
    let animation = CABasicAnimation(keyPath: "strokeEnd")
    animation.duration = 0.5
    animation.repeatCount = 0.0
    animation.fromValue = 0.0
    animation.toValue = 1.0
    animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
    return animation
  }()

  let errorAnimationTop: CABasicAnimation = {
    let errorAnimationTop = CABasicAnimation(keyPath: "strokeEnd")
    errorAnimationTop.duration = 0.5
    errorAnimationTop.repeatCount = 0
    errorAnimationTop.fromValue = 0.0
    errorAnimationTop.toValue = 1.0
    errorAnimationTop.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
    return errorAnimationTop
  }()

  let errorAnimationBottom: CABasicAnimation = {
    let errorAnimationBottom = CABasicAnimation(keyPath: "strokeEnd")
    errorAnimationBottom.duration = 0.5
    errorAnimationBottom.repeatCount = 0
    errorAnimationBottom.fromValue = 0.0
    errorAnimationBottom.toValue = 1.0
    errorAnimationBottom.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
    return errorAnimationBottom
  }()

  var indeterminateDuration: Double = 1.5

  private func generateAnimation() -> CAAnimationGroup {
    let headAnimation = CABasicAnimation(keyPath: "strokeStart")
    headAnimation.beginTime = indeterminateDuration / 3
    headAnimation.fromValue = 0
    headAnimation.toValue = 1
    headAnimation.duration = indeterminateDuration / 1.5
    headAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

    let tailAnimation = CABasicAnimation(keyPath: "strokeEnd")
    tailAnimation.fromValue = 0
    tailAnimation.toValue = 1
    tailAnimation.duration = indeterminateDuration / 1.5
    tailAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

    let groupAnimation = CAAnimationGroup()
    groupAnimation.duration = indeterminateDuration
    groupAnimation.repeatCount = Float.infinity
    groupAnimation.animations = [headAnimation, tailAnimation]
    return groupAnimation
  }

  let rotateAnimation: CABasicAnimation = {
    let animation = CABasicAnimation(keyPath: "transform.rotation")
    animation.fromValue = 0
    animation.toValue = 2 * Double.pi
    animation.duration = 1.5
    animation.repeatCount = Float.infinity
    return animation
  }()

  private func animateForLoading() {
    backgroundShapeLayer.strokeColor = UIColor.grayText.cgColor
    layer.addSublayer(foregroundShapeLayer)
    foregroundShapeLayer.add(generateAnimation(), forKey: "strokeLineAnimation")
    foregroundShapeLayer.add(rotateAnimation, forKey: "transform.rotation.z")
  }

  private func animateForSuccess() {
    backgroundShapeLayer.strokeColor = UIColor.successGreen.cgColor
    layer.addSublayer(checkmarkBackgroundShapeLayer)
    layer.addSublayer(checkmarkForegroundShapeLayer)

    checkmarkForegroundShapeLayer.add(checkmarkAnimation, forKey: "draw")
  }

  private func animateForFailure() {
    backgroundShapeLayer.strokeColor = UIColor.darkPeach.cgColor
    layer.addSublayer(errorForegroundShapeLayerLeftBottom)
    layer.addSublayer(errorForegroundShapeLayerLeftTop)
    layer.addSublayer(errorBackgroundShapeLayerLeftBottom)
    layer.addSublayer(errorBackgroundShapeLayerLeftTop)

    errorForegroundShapeLayerLeftTop.add(errorAnimationTop, forKey: "draw")
    errorForegroundShapeLayerLeftBottom.add(errorAnimationBottom, forKey: "draw")
  }

  private func reset() {
    checkmarkForegroundShapeLayer.removeAllAnimations()
    errorForegroundShapeLayerLeftTop.removeAllAnimations()
    errorForegroundShapeLayerLeftBottom.removeAllAnimations()
    foregroundShapeLayer.removeAllAnimations()

    foregroundShapeLayer.removeFromSuperlayer()
    checkmarkBackgroundShapeLayer.removeFromSuperlayer()
    checkmarkForegroundShapeLayer.removeFromSuperlayer()
    errorBackgroundShapeLayerLeftTop.removeFromSuperlayer()
    errorBackgroundShapeLayerLeftBottom.removeFromSuperlayer()
    errorForegroundShapeLayerLeftTop.removeFromSuperlayer()
    errorForegroundShapeLayerLeftBottom.removeFromSuperlayer()
  }

  private func setupCircle() {
    backgroundBezierPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0,
                                                            width: frame.size.width,
                                                            height: frame.size.height),
                                        byRoundingCorners: .allCorners,
                                        cornerRadii: CGSize(width: frame.size.width / 2.0, height: frame.size.height / 2.0))

    backgroundShapeLayer.path = backgroundBezierPath.cgPath
    backgroundShapeLayer.lineWidth = lineWidth
    backgroundShapeLayer.strokeColor = UIColor.grayText.cgColor
    backgroundShapeLayer.fillColor = UIColor.clear.cgColor
    backgroundShapeLayer.lineCap = CAShapeLayerLineCap.round
    backgroundShapeLayer.bounds = bounds
    backgroundShapeLayer.frame = bounds

    foregroundShapeLayer.path = backgroundBezierPath.cgPath
    foregroundShapeLayer.lineCap = CAShapeLayerLineCap.round
    foregroundShapeLayer.fillColor = UIColor.clear.cgColor
    foregroundShapeLayer.lineWidth = lineWidth
    foregroundShapeLayer.strokeColor = UIColor.lightBlueTint.cgColor
    foregroundShapeLayer.frame = bounds
    foregroundShapeLayer.bounds = bounds

    layer.addSublayer(backgroundShapeLayer)
    layer.addSublayer(foregroundShapeLayer)
  }

  private func setupX() {
    leftTopErrorBezierPath.move(to: CGPoint(x: 49, y: 81))
    leftTopErrorBezierPath.addLine(to: CGPoint(x: 80, y: 50))
    leftTopErrorBezierPath.lineWidth = lineWidth
    leftTopErrorBezierPath.lineCapStyle = .round

    leftBottomErrorBezierPath.move(to: CGPoint(x: 49, y: 50))
    leftBottomErrorBezierPath.addLine(to: CGPoint(x: 80, y: 81))
    leftBottomErrorBezierPath.lineWidth = lineWidth
    leftBottomErrorBezierPath.lineCapStyle = .round

    errorBackgroundShapeLayerLeftTop.path = leftTopErrorBezierPath.cgPath
    errorBackgroundShapeLayerLeftTop.lineCap = CAShapeLayerLineCap.round
    errorBackgroundShapeLayerLeftTop.lineWidth = lineWidth
    errorBackgroundShapeLayerLeftTop.strokeColor = UIColor.grayText.cgColor
    errorBackgroundShapeLayerLeftTop.fillColor = UIColor.clear.cgColor
    errorBackgroundShapeLayerLeftTop.strokeEnd = 1.0
    errorBackgroundShapeLayerLeftTop.zPosition = -1

    errorBackgroundShapeLayerLeftBottom.path = leftBottomErrorBezierPath.cgPath
    errorBackgroundShapeLayerLeftBottom.lineCap = CAShapeLayerLineCap.round
    errorBackgroundShapeLayerLeftBottom.lineWidth = lineWidth
    errorBackgroundShapeLayerLeftBottom.strokeColor = UIColor.grayText.cgColor
    errorBackgroundShapeLayerLeftBottom.fillColor = UIColor.clear.cgColor
    errorBackgroundShapeLayerLeftBottom.strokeEnd = 1.0
    errorBackgroundShapeLayerLeftBottom.zPosition = -1

    errorForegroundShapeLayerLeftTop.path = leftTopErrorBezierPath.cgPath
    errorForegroundShapeLayerLeftTop.lineCap = CAShapeLayerLineCap.round
    errorForegroundShapeLayerLeftTop.lineWidth = lineWidth
    errorForegroundShapeLayerLeftTop.strokeColor = UIColor.darkPeach.cgColor
    errorForegroundShapeLayerLeftTop.fillColor = UIColor.clear.cgColor
    errorForegroundShapeLayerLeftTop.strokeEnd = 1.0

    errorForegroundShapeLayerLeftBottom.path = leftBottomErrorBezierPath.cgPath
    errorForegroundShapeLayerLeftBottom.lineCap = CAShapeLayerLineCap.round
    errorForegroundShapeLayerLeftBottom.lineWidth = lineWidth
    errorForegroundShapeLayerLeftBottom.strokeColor = UIColor.darkPeach.cgColor
    errorForegroundShapeLayerLeftBottom.fillColor = UIColor.clear.cgColor
    errorForegroundShapeLayerLeftBottom.strokeEnd = 1.0
  }

  private func setupCheckmark() {
    checkmarkBezierPath.move(to: CGPoint(x: 35.5, y: 67.5))
    checkmarkBezierPath.move(to: CGPoint(x: 47, y: 67.66))
    checkmarkBezierPath.addCurve(to: CGPoint(x: 58.57, y: 78.5),
                                 controlPoint1: CGPoint(x: 48.93, y: 69.01),
                                 controlPoint2: CGPoint(x: 58.57, y: 78.5))
    checkmarkBezierPath.addLine(to: CGPoint(x: 83, y: 48))
    checkmarkBezierPath.lineWidth = lineWidth
    checkmarkBezierPath.lineCapStyle = .round

    checkmarkBackgroundShapeLayer.path = checkmarkBezierPath.cgPath
    checkmarkBackgroundShapeLayer.lineCap = CAShapeLayerLineCap.round
    checkmarkBackgroundShapeLayer.lineWidth = lineWidth
    checkmarkBackgroundShapeLayer.strokeColor = UIColor.grayText.cgColor
    checkmarkBackgroundShapeLayer.fillColor = UIColor.clear.cgColor
    checkmarkBackgroundShapeLayer.strokeEnd = 1.0
    checkmarkBackgroundShapeLayer.zPosition = -1

    checkmarkForegroundShapeLayer.path = checkmarkBezierPath.cgPath
    checkmarkForegroundShapeLayer.lineCap = CAShapeLayerLineCap.round
    checkmarkForegroundShapeLayer.lineWidth = lineWidth
    checkmarkForegroundShapeLayer.strokeColor = UIColor.successGreen.cgColor
    checkmarkForegroundShapeLayer.fillColor = UIColor.clear.cgColor
    checkmarkForegroundShapeLayer.strokeEnd = 1.0
  }
}
