//
//  StartViewController.swift
//  DropBit
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
  func requireAuthenticationIfNeeded(whenAuthenticated: @escaping CKCompletion)
  func requireAuthenticationIfNeeded()
}

final class StartViewController: BaseViewController {

  static func newInstance(delegate: StartViewControllerDelegate) -> StartViewController {
    let controller = StartViewController.makeFromStoryboard()
    controller.delegate = delegate
    return controller
  }
  
  weak var delegate: StartViewControllerDelegate?

  @IBOutlet var restoreWalletButton: DarkActionButton!
  @IBOutlet var claimInviteButton: DarkActionButton!
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

  static func newInstance(delegate: StartViewControllerDelegate?) -> StartViewController {
    let vc = StartViewController.makeFromStoryboard()
    vc.delegate = delegate
    return vc
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .start(.page)),
      (self.newWalletButton, .start(.newWallet)),
      (self.restoreWalletButton, .start(.restoreWallet))
    ]
  }

  @IBAction func restoreWalletButtonTapped() {
    delegate?.restoreWallet()
  }

  @IBAction func claimBitcoinFromInviteTapped(_ sender: UIButton) {
    delegate?.claimInvite()
  }

  @IBAction func newWalletButtonTapped(_ sender: UIButton) {
    delegate?.createWallet()
  }

  // MARK: view lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    configureButtons()
    toggleAnimatableViews(show: false)
  }

  private func configureButtons() {
    claimInviteButton.setTitle("CLAIM BITCOIN FROM INVITE", for: .normal)
    restoreWalletButton.setTitle("Restore Wallet", for: .normal)

    newWalletButton.setTitle("NEW WALLET", for: .normal)
    newWalletButton.setTitleColor(.lightBlueTint, for: .normal)
    newWalletButton.titleLabel?.font = .primaryButtonTitle
  }

  private func toggleAnimatableViews(show: Bool) {
    guard let views = animatableViews else { return }
    (views + [restoreWalletButton as UIView]).forEach { view in
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
