//
//  StartViewController.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/1/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol StartViewControllerDelegate: AnyObject {
  func createWallet()
  func restoreWallet()
  func clearPin()
  func requireAuthenticationIfNeeded(whenAuthenticated: (() -> Void)?)
}

final class StartViewController: BaseViewController {

  var coordinationDelegate: StartViewControllerDelegate? {
    return generalCoordinationDelegate as? StartViewControllerDelegate
  }

  @IBOutlet var createWalletButton: PrimaryActionButton!
  @IBOutlet var restoreWalletButton: SecondaryActionButton!
  @IBOutlet var blockchainImage: UIImageView!
  @IBOutlet var logoImage: UIImageView!
  @IBOutlet var logoImageVerticalConstraint: NSLayoutConstraint!
  @IBOutlet var welcomeLabel: UILabel!
  @IBOutlet var welcomeBGView: UIView! {
    didSet {
      welcomeBGView.backgroundColor = .clear
    }
  }
  @IBOutlet var welcomeBGViewTopConstraint: NSLayoutConstraint!
  @IBOutlet var animatableViews: [UIView]!

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .start(.page))
    ]
  }

  // MARK: view lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    toggleAnimatableViews(show: false)
  }

  private func toggleAnimatableViews(show: Bool) {
    animatableViews.forEach { view in
      view.alpha = show ? 1.0 : 0.0
      view.isHidden = !show
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    let animationDuration: TimeInterval = 0.75
    let delay: TimeInterval = 0.33
    let offset = ((welcomeBGView.frame.height / 2.0) * -1) - (welcomeBGViewTopConstraint.constant / 2.0)

    // do a layout pass
    view.layoutIfNeeded()

    // set properties to animate
    logoImageVerticalConstraint.constant = offset

    // animate
    UIView.animate(withDuration: animationDuration, delay: delay, options: .curveEaseInOut, animations: {
      self.toggleAnimatableViews(show: true)
      self.view.layoutIfNeeded()
    })
  }

  @IBAction func createWalletButtonTapped(_ sender: UIButton) {
    coordinationDelegate?.createWallet()
  }

  @IBAction func restoreWalletButtonTapped(_ sender: UIButton) {
    coordinationDelegate?.restoreWallet()
  }

  @IBAction func clearPinTapped(_ sender: UIButton) {
    coordinationDelegate?.clearPin()
  }

}

extension StartViewController: StoryboardInitializable {}
