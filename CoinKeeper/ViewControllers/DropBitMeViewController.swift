//
//  DropBitMeViewController.swift
//  DropBit
//
//  Created by Ben Winters on 4/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol DropBitMeViewControllerDelegate: ViewControllerDismissable, CopyToClipboardMessageDisplayable {
  func viewControllerDidEnableDropBitMeURL(_ viewController: UIViewController, shouldEnable: Bool)
  func viewControllerDidTapLearnMore(_ viewController: UIViewController)
  func viewControllerDidSelectVerifyPhone(_ viewController: UIViewController)
  func viewControllerDidTapShareOnTwitter(_ viewController: UIViewController)
}

enum DropBitMeConfig {
  case verified(URL, firstTime: Bool) // true to show "You've been verified!" at top of popover, first time after verification
  case notVerified
  case disabled

  init(publicURLInfo: UserPublicURLInfo?, verifiedFirstTime: Bool) {
    if let info = publicURLInfo {
      if info.private {
        self = .disabled
      } else if let identity = info.primaryIdentity,
        let url = CoinNinjaUrlFactory.buildUrl(for: .dropBitMe(handle: identity.handle)) {
        self = .verified(url, firstTime: verifiedFirstTime)
      } else {
        self = .disabled //this should not be reached since a user cannot exist without an identity
      }
    } else {
      self = .notVerified
    }
  }
}

class DropBitMeViewController: UIViewController, StoryboardInitializable {

  private var config: DropBitMeConfig = .notVerified
  private weak var delegate: DropBitMeViewControllerDelegate!

  @IBOutlet var semiOpaqueBackgroundView: UIView!
  @IBOutlet var avatarButton: UIButton!
  @IBOutlet var avatarButtonTopConstraint: NSLayoutConstraint!
  @IBOutlet var popoverArrowImage: UIImageView!
  @IBOutlet var popoverBackgroundView: UIView!

  @IBOutlet var verificationSuccessButton: UIButton! // use button for built-in content inset handling
  @IBOutlet var headerSpacer: UIView!
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
      delegate.viewControllerDidSelectVerifyPhone(self)
    case .disabled:
      delegate.viewControllerDidEnableDropBitMeURL(self, shouldEnable: true)
    }
  }

  @IBAction func performSecondaryAction(_ sender: Any) {
    switch config {
    case .verified:
      delegate.viewControllerDidEnableDropBitMeURL(self, shouldEnable: false)
    case .disabled:
      delegate.viewControllerDidTapLearnMore(self)
    case .notVerified:
      break
    }
  }

  static func newInstance(config: DropBitMeConfig, delegate: DropBitMeViewControllerDelegate) -> DropBitMeViewController {
    let vc = DropBitMeViewController.makeFromStoryboard()
    vc.modalTransitionStyle = .crossDissolve
    vc.modalPresentationStyle = .overFullScreen
    vc.config = config
    vc.delegate = delegate
    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    semiOpaqueBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    popoverBackgroundView.layer.masksToBounds = true
    popoverBackgroundView.layer.cornerRadius = 10

    setupVerificationSuccessButton()

    messageLabel.textColor = Theme.Color.darkBlueText.color
    messageLabel.font = Theme.Font.popoverMessage.font

    dropBitMeURLButton.titleLabel?.font = Theme.Font.popoverMessage.font
    dropBitMeURLButton.setTitleColor(Theme.Color.darkBlueText.color, for: .normal)

    secondaryButton.setTitleColor(Theme.Color.darkBlueText.color, for: .normal)
    secondaryButton.titleLabel?.font = Theme.Font.popoverSecondaryButton.font

    configure(with: self.config)
  }

  private func setupVerificationSuccessButton() {
    verificationSuccessButton.isUserInteractionEnabled = false
    verificationSuccessButton.setTitle("You've been verified!", for: .normal)
    verificationSuccessButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
    verificationSuccessButton.layer.masksToBounds = true
    verificationSuccessButton.layer.cornerRadius = verificationSuccessButton.frame.height/2
    verificationSuccessButton.backgroundColor = Theme.Color.primaryActionButton.color
    verificationSuccessButton.setTitleColor(Theme.Color.whiteText.color, for: .normal)
    verificationSuccessButton.titleLabel?.font = Theme.Font.popoverStatusLabel.font
  }

  func configure(with config: DropBitMeConfig) {
    self.config = config
    self.messageLabel.text = self.message
    dropBitMeURLButton.isHidden = true
    verificationSuccessButton.isHidden = true

    switch config {
    case .verified(let url, let firstTimeVerified):
      verificationSuccessButton.isHidden = !firstTimeVerified
      headerSpacer.isHidden = firstTimeVerified
      dropBitMeURLButton.setTitle(url.absoluteString, for: .normal)
      dropBitMeURLButton.isHidden = false
      primaryButton.style = .standard
      primaryButton.setTitle("SHARE ON TWITTER", for: .normal)
      secondaryButton.setTitle("Disable my DropBit.me URL", for: .normal)
    case .notVerified:
      primaryButton.style = .standard
      primaryButton.setTitle("VERIFY MY ACCOUNT", for: .normal)
      secondaryButton.isHidden = true

    case .disabled:
      primaryButton.style = .darkBlue
      primaryButton.setTitle("ENABLE MY URL", for: .normal)
    }
  }

  private var message: String {
    switch config {
    case .verified:
      return "DropBit.me is your personal URL created to safely request and receive Bitcoin. Keep this URL and share freely."
    case .notVerified:
      return """
      Verifying your account with phone or Twitter will also allow you to send Bitcoin without an address.

      You will then be given a DropBit.me URL to safely request and receive Bitcoin.
      """
    case .disabled:
      return "DropBit.me is a personal URL created to safely request and receive Bitcoin directly to your wallet."
    }
  }
}
