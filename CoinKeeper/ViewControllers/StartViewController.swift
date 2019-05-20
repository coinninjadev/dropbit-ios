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
  func claimInvite()
  func clearPin()
  func requireAuthenticationIfNeeded(whenAuthenticated: (() -> Void)?)
}

final class StartViewController: BaseViewController {

  var coordinationDelegate: StartViewControllerDelegate? {
    return generalCoordinationDelegate as? StartViewControllerDelegate
  }

  @IBOutlet var restoreWalletButton: UIButton!
  @IBOutlet var claimInviteButton: UIButton!
  @IBOutlet var newWalletButton: UIButton!

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
      (self.view, .start(.page)),
      (self.newWalletButton, .start(.newWallet)),
      (self.restoreWalletButton, .start(.restoreWallet))
    ]
  }

  @IBAction func restoreWalletButtonTapped(_ sender: UIButton) {
    coordinationDelegate?.restoreWallet()
  }

  @IBAction func claimBitcoinFromInviteTapped(_ sender: UIButton) {
    coordinationDelegate?.claimInvite()
  }

  @IBAction func newWalletButtonTapped(_ sender: UIButton) {
    coordinationDelegate?.createWallet()
  }

  // MARK: view lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    configureButtons()
    toggleAnimatableViews(show: false)
  }

  private func configureButtons() {
    let restoreTitle = NSAttributedString(imageName: "rightArrow",
                                          imageSize: CGSize(width: 8, height: 12),
                                          title: "Restore Wallet",
                                          sharedColor: Theme.Color.darkBlueText.color,
                                          font: Theme.Font.restoreWalletButton.font,
                                          imageOffset: CGPoint(x: 0, y: 1),
                                          trailingImage: true)
    restoreWalletButton.setAttributedTitle(restoreTitle, for: .normal)

    claimInviteButton.setTitle("CLAIM BITCOIN FROM INVITE", for: .normal)
    claimInviteButton.backgroundColor = Theme.Color.darkBlueButton.color
    claimInviteButton.applyCornerRadius(4)
    claimInviteButton.setTitleColor(Theme.Color.whiteText.color, for: .normal)
    claimInviteButton.titleLabel?.font = Theme.Font.primaryButtonTitle.font

    newWalletButton.setTitle("NEW WALLET", for: .normal)
    newWalletButton.setTitleColor(Theme.Color.lightBlueTint.color, for: .normal)
    newWalletButton.titleLabel?.font = Theme.Font.primaryButtonTitle.font
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

}

extension StartViewController: StoryboardInitializable {}
