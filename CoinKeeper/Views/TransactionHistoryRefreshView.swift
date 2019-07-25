//
//  TransactionHistoryRefreshView.swift
//  DropBit
//
//  Created by Mitch on 1/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class TransactionHistoryRefreshView: UIView {

  @IBOutlet var bitcoinImageViewTopConstraint: NSLayoutConstraint!
  @IBOutlet var bitcoinImageView: UIImageView!
  private var feedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
  private var bitcoinImage: UIImage = UIImage(imageLiteralResourceName: "pullBitcoinIcon")
  private var coinNinjaImage: UIImage = UIImage(imageLiteralResourceName: "pullCoinNinjaIcon")
  private var refreshOffsetThreshhold: CGFloat = 0.0
  private var defaultTopConstraintConstant: CGFloat = 86.0
  var shouldQueueRefresh: Bool = false
  var isAnimating: Bool = false

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initalize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initalize()
  }

  private func initalize() {
    xibSetup()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    clipsToBounds = false

    let maskLayer = CALayer()
    maskLayer.frame = CGRect(x: 0, y: -frame.size.height, width: frame.size.width, height: frame.size.height * 2)
    maskLayer.backgroundColor = UIColor.black.cgColor
    layer.mask = maskLayer
  }

  func animateLogo(to offset: CGFloat) {
    guard !isAnimating else { return }

    bitcoinImageViewTopConstraint.constant = max(defaultTopConstraintConstant + (offset * 1.3), refreshOffsetThreshhold)
    if bitcoinImageViewTopConstraint.constant <= refreshOffsetThreshhold {
      if !shouldQueueRefresh {
        shouldQueueRefresh = true
        feedbackGenerator.impactOccurred()
      }
    } else {
      shouldQueueRefresh = false
    }
  }

  func fireRefreshAnimationIfNecessary() {
    guard shouldQueueRefresh else {
      reset()
      return
    }

    bitcoinImageView.image = coinNinjaImage
    bitcoinImageViewTopConstraint.constant = -bitcoinImageView.frame.size.height * 2

    UIView.animate(
      withDuration: 0.4,
      animations: { [weak self] in
        self?.isAnimating = true
        self?.layoutIfNeeded()
      },
      completion: { [weak self] _ in self?.reset() }
    )
  }

  func reset() {
    bitcoinImageView.image = bitcoinImage
    shouldQueueRefresh = false
    isAnimating = false
    bitcoinImageViewTopConstraint.constant = defaultTopConstraintConstant
    layoutIfNeeded()
  }
}
