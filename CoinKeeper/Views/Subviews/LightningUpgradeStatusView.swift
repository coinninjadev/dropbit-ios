//
//  LightningUpgradeStatusView.swift
//  DropBit
//
//  Created by BJ Miller on 9/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class LightningUpgradeStatusView: UIView {

  private let notStartedImage = UIImage(imageLiteralResourceName: "circleCheckPurple")
  private let completedImage = UIImage(imageLiteralResourceName: "circleCheckGreen")

  enum Mode {
    case notStarted
    case working
    case finished
  }

  @IBOutlet var statusImageView: UIImageView!
  @IBOutlet var activityIndicator: UIActivityIndicatorView!

  var mode: Mode = .notStarted {
    didSet {
      switch mode {
      case .notStarted:
        statusImageView.image = notStartedImage
        activityIndicator.isHidden = true
        statusImageView.isHidden = false
      case .working:
        statusImageView.image = nil
        statusImageView.isHidden = true
        activityIndicator.isHidden = false
      case .finished:
        statusImageView.image = completedImage
        statusImageView.isHidden = false
        activityIndicator.isHidden = true
      }
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  private func initialize() {
    xibSetup()
  }

}
