//
//  VerticalDragView.swift
//  DropBit
//
//  Created by Mitch on 10/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol VerticalDragViewControllerDelegate: class {
  func viewDragChanged(_ view: VerticalDragView, to translation: VerticalTranslation)
  func viewEndedDrag(_ view: VerticalDragView, to translation: VerticalTranslation)
}

struct VerticalTranslation {
  enum Direction {
    case up
    case down
    case neither
  }

  var toPoint: CGPoint {
    willSet {
      if newValue.y < toPoint.y {
        direction = .up
      } else {
        direction = .down
      }
    }
  }

  var direction: Direction

  init(translation: CGPoint) {
    toPoint = translation
    direction = .neither
  }
}

class VerticalDragView: UIView {

  enum Position {
    case top
    case bottom
  }

  lazy private var dragPanGestureRecognizer: UIPanGestureRecognizer = {
    return UIPanGestureRecognizer(target: self, action: #selector(gestureRecognizerDidPan(recognizer:)))
  }()

  var upperPercentageLimit: CGFloat = 0.10
  var lowerPercentageLimit: CGFloat = 0.85

  var upperBoundConstant: CGFloat {
    return UIScreen.main.bounds.height * upperPercentageLimit
  }

  var lowerBoundConstant: CGFloat {
    return UIScreen.main.bounds.height * lowerPercentageLimit
  }

  var heightConstraintConstant: CGFloat {
    return lowerBoundConstant + 40 //Safe area constant
  }

  var dragViewTopMargin: CGFloat {
    return 15.0
  }

  private var dragIndiciatorView: DragIndicatiorView = DragIndicatiorView()
  private var currentTranslation: VerticalTranslation = VerticalTranslation(translation: CGPoint(x: 0, y: 0))

  weak var dragDelegate: VerticalDragViewControllerDelegate?

  var position: Position = .bottom

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupUI()
  }

  override func draw(_ rect: CGRect) {
    super.draw(rect)
    bringSubviewToFront(dragIndiciatorView)

    addShadowView()
  }

  private func setupUI() {
    addGestureRecognizer(dragPanGestureRecognizer)
    addSubview(dragIndiciatorView)

    layer.cornerRadius = 13
    layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    clipsToBounds = true

    setupConstraints()
  }

  private func setupConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    dragIndiciatorView.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
    dragIndiciatorView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0).isActive = true
  }

  private func isTranslationStayingWithinDragLimits(_ translation: CGPoint) -> Bool {
    if translation.y == 0 { return true }

    switch position {
    case .top:
      return translation.y > 0
    case .bottom:
      return translation.y < 0
    }
  }

  @objc private func gestureRecognizerDidPan(recognizer: UIPanGestureRecognizer) {
    guard let delegate = dragDelegate, let superview = superview  else { return }

    let translation = recognizer.translation(in: superview)
    guard isTranslationStayingWithinDragLimits(translation) else { return }

    switch recognizer.state {
    case .began:
      currentTranslation = VerticalTranslation(translation: translation)
    case .changed:
      currentTranslation.toPoint = translation
      delegate.viewDragChanged(self, to: currentTranslation)
    case .ended:
      delegate.viewEndedDrag(self, to: currentTranslation)
      switch currentTranslation.direction {
      case .up:
        position = .top
      case .down, .neither:
        position = .bottom
      }
    default:
      break
    }
  }
}
