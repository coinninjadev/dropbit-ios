//
//  VerificationStatusViewController.swift
//  DropBit
//
//  Created by Mitch on 10/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol VerificationStatusViewControllerDelegate: ViewControllerDismissable, AuthenticationSuspendable, ViewControllerURLDelegate {
  func verifiedPhoneNumber() -> GlobalPhoneNumber?
  func verifiedTwitterHandle() -> String?
  func viewControllerDidRequestAddresses() -> [ServerAddressViewModel]
  func viewControllerDidSelectVerifyPhone(_ viewController: UIViewController)
  func viewControllerDidSelectVerifyTwitter(_ viewController: UIViewController)
  func viewControllerDidRequestToUnverifyPhone(_ viewController: UIViewController, successfulCompletion: @escaping CKCompletion)
  func viewControllerDidRequestToUnverifyTwitter(_ viewController: UIViewController, successfulCompletion: @escaping CKCompletion)
}

class VerificationStatusViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var serverAddressViewVerticalConstraint: NSLayoutConstraint!
  @IBOutlet var serverAddressView: ServerAddressView!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var serverAddressBackgroundView: UIView!
  @IBOutlet var phoneNumberNavigationTitle: UILabel!
  @IBOutlet var privacyLabel: UILabel!
  @IBOutlet var verifyPhoneNumberPrimaryButton: PrimaryActionButton!
  @IBOutlet var verifyTwitterPrimaryButton: PrimaryActionButton!
  @IBOutlet var changeRemovePhoneButton: ChangeRemoveVerificationButton!
  @IBOutlet var changeRemoveTwitterButton: ChangeRemoveVerificationButton!
  @IBOutlet var phoneVerificationStatusView: VerifiedStatusView!
  @IBOutlet var twitterVerificationStatusView: VerifiedStatusView!
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var addressButton: UIButton!

  fileprivate weak var delegate: VerificationStatusViewControllerDelegate!

  let serverAddressUpperPercentageMultiplier: CGFloat = 0.15

  static func newInstance(delegate: VerificationStatusViewControllerDelegate) -> VerificationStatusViewController {
    let vc = VerificationStatusViewController.makeFromStoryboard()
    vc.delegate = delegate
    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  private func setupUI() {
    verifyPhoneNumberPrimaryButton.style = .darkBlue
    verifyTwitterPrimaryButton.style = .standard
    privacyLabel.font = .light(13)
    privacyLabel.textColor = .darkBlueText
    phoneNumberNavigationTitle.font = .regular(15)
    phoneNumberNavigationTitle.textColor = .darkBlueText
    titleLabel.font = .regular(15)
    titleLabel.textColor = .darkGrayText
    serverAddressView.delegate = self
    serverAddressViewVerticalConstraint.constant = UIScreen.main.bounds.height

    // phone number start
    if let phoneNumber = delegate.verifiedPhoneNumber() {
      let formatter = CKPhoneNumberFormatter(format: .national)
      phoneVerificationStatusView.isHidden = false
      changeRemovePhoneButton.isHidden = false
      verifyPhoneNumberPrimaryButton.isHidden = true
      do {
        let identity = try formatter.string(from: phoneNumber)
        phoneVerificationStatusView.load(with: .phone, identityString: identity)
      } catch {
        phoneVerificationStatusView.load(with: .phone, identityString: phoneNumber.asE164())
      }
    } else {
      phoneVerificationStatusView.isHidden = true
      let verifyPhoneButtonTitle = NSAttributedString(
        imageName: "phoneDrawerIcon",
        imageSize: CGSize(width: 13, height: 22),
        title: "VERIFY PHONE NUMBER",
        sharedColor: .lightGrayText,
        font: .regular(17))
      verifyPhoneNumberPrimaryButton.setTitle(nil, for: .normal)
      verifyPhoneNumberPrimaryButton.setAttributedTitle(verifyPhoneButtonTitle, for: .normal)
      changeRemovePhoneButton.isHidden = true
      verifyPhoneNumberPrimaryButton.isHidden = false
    }
    // phone number end

    // twitter start
    if let handle = delegate.verifiedTwitterHandle() {
      twitterVerificationStatusView.isHidden = false
      changeRemoveTwitterButton.isHidden = false
      verifyTwitterPrimaryButton.isHidden = true
      let identity = handle
      twitterVerificationStatusView.load(with: .twitter, identityString: identity)
    } else {
      twitterVerificationStatusView.isHidden = true
      changeRemoveTwitterButton.isHidden = true
      verifyTwitterPrimaryButton.isHidden = false
      verifyTwitterPrimaryButton.setTitle(nil, for: .normal)

      let verifyTwitterButtonTitle = NSAttributedString(
        imageName: "twitterBird",
        imageSize: CGSize(width: 20, height: 16),
        title: "VERIFY TWITTER ACCOUNT",
        sharedColor: .lightGrayText,
        font: .regular(17))

      verifyTwitterPrimaryButton.setAttributedTitle(verifyTwitterButtonTitle, for: .normal)
    }
    // twitter end

    setupAddressUI()

    let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.lightBlueTint,
                                                     .font: UIFont.regular(14),
                                                     .underlineStyle: 1,
                                                     .underlineColor: UIColor.lightBlueTint]

    let attributedString = NSAttributedString(string: "View DropBit addresses", attributes: attributes)
    addressButton.setAttributedTitle(attributedString, for: .normal)

    view.layoutIfNeeded()
  }

  private func setupAddressUI() {
    // Hide address elements if no addresses exist or words aren't backed up
    let addresses = delegate.viewControllerDidRequestAddresses()
    if addresses.isNotEmpty {
      serverAddressView.addresses = addresses
      addressButton.isHidden = false
      serverAddressView.isHidden = false
    } else {
      addressButton.isHidden = true
      serverAddressView.isHidden = true
    }
  }

  @IBAction func closeButtonWasTouched() {
    delegate.viewControllerDidSelectClose(self)
  }

  @IBAction func addressButtonWasTouched() {
    UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
      guard let strongSelf = self else { return }
      self?.serverAddressBackgroundView.alpha = 0.5
      self?.serverAddressViewVerticalConstraint.constant = UIScreen.main.bounds.height * strongSelf.serverAddressUpperPercentageMultiplier
      self?.view.layoutIfNeeded()
    })
  }

  @IBAction func verifyPhoneNumber() {
    delegate.viewControllerDidSelectVerifyPhone(self)
  }

  @IBAction func verifyTwitter() {
    delegate.viewControllerRequestedAuthenticationSuspension(self)
    delegate.viewControllerDidSelectVerifyTwitter(self)
  }

  @IBAction func changeRemovePhone() {
    delegate.viewControllerDidRequestToUnverifyPhone(self, successfulCompletion: { [weak self] in
      self?.setupUI()
    })
  }

  @IBAction func changeRemoveTwitter() {
    delegate.viewControllerDidRequestToUnverifyTwitter(self, successfulCompletion: { [weak self] in
      self?.setupUI()
    })
  }
}

extension VerificationStatusViewController: ServerAddressViewDelegate {
  func didPressCloseButton() {
    UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
      self?.serverAddressBackgroundView.alpha = 0.0
      self?.serverAddressViewVerticalConstraint.constant = UIScreen.main.bounds.height
      self?.view.layoutIfNeeded()
    })
  }

  func didPressQuestionMarkButton() {
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .myAddressesTooltip) else { return }
    delegate.viewController(self, didRequestOpenURL: url)
  }
}
