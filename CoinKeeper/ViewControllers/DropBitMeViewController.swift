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

struct DropBitMeConfig {
  enum DropBitMeState {
    /// firstTime as true shows "You've been verified!" at top of popover, first time after verification
    case verified(URL, firstTime: Bool)
    case notVerified
    case disabled
  }

  var state: DropBitMeState = .notVerified
  var avatar: UIImage?

  init(publicURLInfo: UserPublicURLInfo?, verifiedFirstTime: Bool, userAvatarData: Data? = nil) {
    if let info = publicURLInfo {
      if info.private {
        self.state = .disabled
      } else if let identity = info.primaryIdentity,
        let url = CoinNinjaUrlFactory.buildUrl(for: .dropBitMe(handle: identity.handle)) {
        self.state = .verified(url, firstTime: verifiedFirstTime)
      } else {
        self.state = .disabled // this should not be reached since a user cannot exist without an identity
      }
    } else {
      self.state = .notVerified
    }

    userAvatarData.map { self.avatar = UIImage(data: $0) }
  }

  init(state: DropBitMeState, userAvatarData: Data? = nil) {
    self.state = state
    userAvatarData.map { self.avatar = UIImage(data: $0) }
  }
}

class DropBitMeViewController: UIViewController, StoryboardInitializable {

  private var config: DropBitMeConfig = DropBitMeConfig(publicURLInfo: nil, verifiedFirstTime: false)
  private weak var delegate: DropBitMeViewControllerDelegate!

  @IBOutlet var semiOpaqueBackgroundView: UIView!
  @IBOutlet var avatarButton: UIButton! {
    didSet {
      let radius = avatarButton.frame.width / 2.0
      avatarButton.applyCornerRadius(radius)
    }
  }
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
  @IBOutlet var avatarImageView: UIImageView!

  @IBAction func performClose(_ sender: Any) {
    delegate.viewControllerDidSelectClose(self)
  }

  @IBAction func performAvatar(_ sender: Any) {
    delegate.viewControllerDidSelectClose(self)
  }

  @IBAction func copyDropBitURL(_ sender: Any) {
    guard case let .verified(dropBitMeURL, _) = self.config.state else { return }
    UIPasteboard.general.string = dropBitMeURL.absoluteString
    delegate.viewControllerSuccessfullyCopiedToClipboard(message: "DropBit.me URL copied!", viewController: self)
  }

  @IBAction func performPrimaryAction(_ sender: Any) {
    switch config.state {
    case .verified:
      delegate.viewControllerDidTapShareOnTwitter(self)
    case .notVerified:
      delegate.viewControllerDidSelectVerifyPhone(self)
    case .disabled:
      delegate.viewControllerDidEnableDropBitMeURL(self, shouldEnable: true)
    }
  }

  @IBAction func performSecondaryAction(_ sender: Any) {
    switch config.state {
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

    avatarButton.alpha = 0.0
    semiOpaqueBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    popoverBackgroundView.layer.masksToBounds = true
    popoverBackgroundView.layer.cornerRadius = 10

    setupVerificationSuccessButton()

    messageLabel.textColor = .darkBlueText
    messageLabel.font = .popoverMessage

    dropBitMeURLButton.titleLabel?.font = .popoverMessage
    dropBitMeURLButton.setTitleColor(.darkBlueText, for: .normal)

    secondaryButton.setTitleColor(.darkBlueText, for: .normal)
    secondaryButton.titleLabel?.font = .semiBold(12)

    configure(with: self.config)
  }

  private func setupVerificationSuccessButton() {
    verificationSuccessButton.isUserInteractionEnabled = false
    verificationSuccessButton.setTitle("You've been verified!", for: .normal)
    verificationSuccessButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
    verificationSuccessButton.layer.masksToBounds = true
    verificationSuccessButton.layer.cornerRadius = verificationSuccessButton.frame.height/2
    verificationSuccessButton.backgroundColor = .primaryActionButton
    verificationSuccessButton.setTitleColor(.whiteText, for: .normal)
    verificationSuccessButton.titleLabel?.font = .semiBold(14)
  }

  func configure(with config: DropBitMeConfig) {
    self.config = config
    self.messageLabel.text = self.message
    dropBitMeURLButton.isHidden = true
    verificationSuccessButton.isHidden = true
    secondaryButton.isHidden = false

    switch config.state {
    case .verified(let url, let firstTimeVerified):
      verificationSuccessButton.isHidden = !firstTimeVerified
      headerSpacer.isHidden = firstTimeVerified
      dropBitMeURLButton.setTitle(url.absoluteString, for: .normal)
      dropBitMeURLButton.isHidden = false
      primaryButton.style = .standard
      primaryButton.setTitle("SHARE ON TWITTER", for: .normal)
      secondaryButton.setTitle("Disable my DropBit.me URL", for: .normal)
      avatarButton.alpha = 1.0
      avatarButton.setImage(config.avatar, for: .normal)
      avatarImageView.image = config.avatar
      let radius = avatarImageView.frame.width / 2.0
      avatarImageView.applyCornerRadius(radius)
    case .notVerified:
      primaryButton.style = .standard
      primaryButton.setTitle("VERIFY MY ACCOUNT", for: .normal)
      secondaryButton.isHidden = true
      avatarButton.alpha = 0.0
      avatarImageView.image = nil

    case .disabled:
      primaryButton.style = .darkBlue
      primaryButton.setTitle("ENABLE MY URL", for: .normal)
      secondaryButton.setTitle("Learn more", for: .normal)
      avatarButton.alpha = 0.0
      avatarImageView.image = nil
    }
  }

  private var message: String {
    switch config.state {
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
