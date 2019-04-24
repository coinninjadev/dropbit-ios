//
//  DropBitMeViewController.swift
//  DropBit
//
//  Created by Ben Winters on 4/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol DropBitMeViewControllerDelegate: ViewControllerDismissable, CopyToClipboardMessageDisplayable {
  func viewControllerDidTapEnableDropBitMeURL(_ viewController: UIViewController)
  func viewControllerDidTapDisableDropBitMeURL(_ viewController: UIViewController)
  func viewControllerDidTapLearnMore(_ viewController: UIViewController)
  func viewControllerDidTapVerifyAccount(_ viewController: UIViewController)
  func viewControllerDidTapShareOnTwitter(_ viewController: UIViewController)
}

enum DropBitMeConfig {
  case verified(URL, Bool) // true to show "You've been verified!" first time after verification
  case notVerified
  case disabled
}

class DropBitMeViewController: UIViewController, StoryboardInitializable {

  private var config: DropBitMeConfig = .notVerified
  private var avatarImageFrame: CGRect!
  private weak var delegate: DropBitMeViewControllerDelegate!

  @IBOutlet var semiOpaqueBackgroundView: UIView!
  @IBOutlet var avatarButton: UIButton!
  @IBOutlet var avatarButtonTopConstraint: NSLayoutConstraint!
  @IBOutlet var popoverArrowImage: UIImageView!
  @IBOutlet var popoverBackgroundView: UIView!

  @IBOutlet var verificationSuccessView: UIView!
  @IBOutlet var dropBitMeLogo: UIImageView!
  @IBOutlet var messageLabel: UILabel!
  @IBOutlet var dropBitMeURLButton: LightBorderedButton!
  @IBOutlet var primaryButton: PrimaryActionButton!
  @IBOutlet var secondaryButton: UIButton!

  @IBAction func performClose(_ sender: Any) {
    delegate.viewControllerDidSelectClose(self)
  }

  @IBAction func performAvatar(_ sender: Any) {
    delegate.viewControllerDidSelectClose(self)
  }

  @IBAction func copyDropBitURL(_ sender: Any) {
    guard case let .verified(dropBitMeURL, _) = self.config else { return }
    UIPasteboard.general.string = dropBitMeURL.absoluteString
    delegate.viewControllerSuccessfullyCopiedToClipboard(message: "DropBit.me URL copied!", viewController: self)
  }

  @IBAction func performPrimaryAction(_ sender: Any) {
    switch config {
    case .verified:
      delegate.viewControllerDidTapShareOnTwitter(self)
    case .notVerified:
      delegate.viewControllerDidTapVerifyAccount(self)
    case .disabled:
      delegate.viewControllerDidTapEnableDropBitMeURL(self)
    }
  }

  @IBAction func performSecondaryAction(_ sender: Any) {
    switch config {
    case .verified:
      delegate.viewControllerDidTapDisableDropBitMeURL(self)
    case .disabled:
      delegate.viewControllerDidTapLearnMore(self)
    case .notVerified:
      break
    }
  }

  static func newInstance(config: DropBitMeConfig, avatarFrame: CGRect, delegate: DropBitMeViewControllerDelegate) -> DropBitMeViewController {
    let vc = DropBitMeViewController.makeFromStoryboard()
    vc.modalTransitionStyle = .crossDissolve
    vc.modalPresentationStyle = .overFullScreen
    vc.config = config
    vc.avatarImageFrame = avatarFrame
    vc.delegate = delegate
    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    semiOpaqueBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    avatarButtonTopConstraint.constant = -self.avatarImageFrame.minY
    avatarButton.setNeedsUpdateConstraints()
    popoverBackgroundView.layer.masksToBounds = true
    popoverBackgroundView.layer.cornerRadius = 10

    messageLabel.textColor = Theme.Color.darkBlueText.color
    messageLabel.font = Theme.Font.popoverMessage.font

    dropBitMeURLButton.titleLabel?.font = Theme.Font.popoverMessage.font
    dropBitMeURLButton.setTitleColor(Theme.Color.darkBlueText.color, for: .normal)

    secondaryButton.setTitleColor(Theme.Color.darkBlueText.color, for: .normal)
    secondaryButton.titleLabel?.font = Theme.Font.popoverSecondaryButton.font

    configure(with: self.config)
  }

  private func configure(with config: DropBitMeConfig) {
    self.config = config
    self.messageLabel.text = self.message

    switch config {
    case .verified(let url, let firstTimeVerified):
      verificationSuccessView.isHidden = !firstTimeVerified
      dropBitMeURLButton.setTitle(url.absoluteString, for: .normal)
      primaryButton.style = .standard
      primaryButton.setTitle("SHARE ON TWITTER", for: .normal)
      secondaryButton.setTitle("Disable my DropBit.me URL", for: .normal)
    case .notVerified:
      primaryButton.style = .standard
      primaryButton.setTitle("VERIFY MY ACCOUNT", for: .normal)
      verificationSuccessView.isHidden = true
      secondaryButton.isHidden = true

    case .disabled:
      primaryButton.style = .darkBlue
      primaryButton.setTitle("ENABLE MY URL", for: .normal)
    }
  }

  private var message: String {
    switch config {
    case .verified:
      return "DropBit.me is your personal webpage created to safely request and receive Bitcoin. Keep this URL and share freely."
    case .notVerified:
      return """
      Verifying your account with phone or Twitter will also allow you to send Bitcoin without an address.

      You will then be given a DropBit.me webpage to safely request and receive Bitcoin.
      """
    case .disabled:
      return "DropBit.me is a personal webpage created to safely request and receive Bitcoin directly to your wallet."
    }
  }
}
