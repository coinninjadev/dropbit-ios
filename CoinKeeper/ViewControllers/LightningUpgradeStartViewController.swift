//
//  LightningUpgradeStartViewController.swift
//  DropBit
//
//  Created by BJ Miller on 8/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol LightningUpgradeStartViewControllerDelegate: AnyObject {
  func viewControllerRequestedShowLightningUpgradeInfo(_ viewController: LightningUpgradeStartViewController)
  func viewControllerRequestedUpgradeToLightning(_ viewController: LightningUpgradeStartViewController)
}

final class LightningUpgradeStartViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var overlayView: UIView!
  @IBOutlet var lightningTitleLabel: UILabel!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var upgradeButton: PrimaryActionButton!
  @IBOutlet var infoButton: UIButton!
  @IBOutlet var activityIndicator: UIActivityIndicatorView!
  @IBOutlet var activityIndicatorBottomConstraint: NSLayoutConstraint!
  @IBOutlet var confirmNewWordsSelectionView: UIView!
  @IBOutlet var confirmTransferFundsView: UIView!

  static func newInstance(withDelegate delegate: LightningUpgradeStartViewControllerDelegate) -> LightningUpgradeStartViewController {
    let controller = LightningUpgradeStartViewController.makeFromStoryboard()
    controller.generalCoordinationDelegate = delegate
    return controller
  }

  var coordinationDelegate: LightningUpgradeStartViewControllerDelegate? {
    return generalCoordinationDelegate as? LightningUpgradeStartViewControllerDelegate
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    styleUI()

  }

  // to be called from owner when balance is provided
  func updateUI(withBalance balance: Int) {
    // set activity indicator new distance
    let distance = (upgradeButton.frame.height / 2.0)
    activityIndicatorBottomConstraint.constant = -distance
    let duration: TimeInterval = 0.25

    UIView.animate(
      withDuration: duration,
      delay: 0.1,
      options: .curveEaseIn,
      animations: { self.view.layoutIfNeeded() },
      completion: { (_) in
        self.activityIndicator.isHidden = true

        // show the checkboxes
        self.confirmNewWordsSelectionView.isHidden = false
        self.confirmTransferFundsView.isHidden = false
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }

      }
    )

    // enable the upgrade button
    self.upgradeButton.style = .white(enabled: true)
  }

  private func styleUI() {
    overlayView.applyCornerRadius(15)
    let gradient = CAGradientLayer()
    gradient.frame = overlayView.bounds
    gradient.colors = [UIColor.mediumPurple.cgColor, UIColor.darkPurple.cgColor]
    overlayView.layer.addSublayer(gradient)

    lightningTitleLabel.textColor = .white
    lightningTitleLabel.font = .regular(18)
    detailLabel.textColor = .neonGreen
    detailLabel.font = .regular(14)

    upgradeButton.style = .white(enabled: false)

    confirmNewWordsSelectionView.backgroundColor = .deepPurple
    confirmNewWordsSelectionView.isHidden = true
    confirmNewWordsSelectionView.applyCornerRadius(8)
    confirmTransferFundsView.backgroundColor = .deepPurple
    confirmTransferFundsView.isHidden = true
    confirmTransferFundsView.applyCornerRadius(8)
  }

  @IBAction func showInfo(_ sender: UIButton) {
    coordinationDelegate?.viewControllerRequestedShowLightningUpgradeInfo(self)
  }

  @IBAction func upgradeNow(_ sender: UIButton) {
    coordinationDelegate?.viewControllerRequestedUpgradeToLightning(self)
  }
}
