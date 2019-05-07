//
//  PhoneNumberStatusViewController.swift
//  DropBit
//
//  Created by Mitch on 10/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import PhoneNumberKit

protocol PhoneNumberStatusViewControllerDelegate: ViewControllerDismissable {
  func verifiedPhoneNumber() -> GlobalPhoneNumber?
  func verifiedTwitterHandle() -> String?
  func viewControllerDidRequestAddresses() -> [ServerAddressViewModel]
  func viewControllerDidRequestOpenURL(_ viewController: UIViewController, url: URL)
  func viewControllerDidSelectVerifyPhone(_ viewController: UIViewController)
  func viewControllerDidSelectVerifyTwitter(_ viewController: UIViewController)
  func viewControllerDidRequestToUnverifyPhone(_ viewController: UIViewController, successfulCompletion: @escaping () -> Void)
  func viewControllerDidRequestToUnverifyTwitter(_ viewController: UIViewController, successfulCompletion: @escaping () -> Void)
}

class PhoneNumberStatusViewController: BaseViewController, StoryboardInitializable {

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

  var coordinationDelegate: PhoneNumberStatusViewControllerDelegate? {
    return generalCoordinationDelegate as? PhoneNumberStatusViewControllerDelegate
  }

  let serverAddressUpperPercentageMultiplier: CGFloat = 0.15
  let phoneNumberKit = PhoneNumberKit()

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  private func setupUI() {
    verifyPhoneNumberPrimaryButton.style = .darkBlue
    verifyTwitterPrimaryButton.style = .standard
    privacyLabel.font = Theme.Font.phoneNumberStatusPrivacy.font
    privacyLabel.textColor = Theme.Color.darkBlueText.color
    phoneNumberNavigationTitle.font = Theme.Font.onboardingSubtitle.font
    phoneNumberNavigationTitle.textColor = Theme.Color.darkBlueText.color
    titleLabel.font = Theme.Font.phoneNumberStatusTitle.font
    titleLabel.textColor = Theme.Color.grayText.color
    serverAddressView.delegate = self
    serverAddressViewVerticalConstraint.constant = UIScreen.main.bounds.height

    let verifyButtonAttributes: [NSAttributedString.Key: AnyObject] = [
      .font: Theme.Font.verificationActionTitle.font,
      .foregroundColor: Theme.Color.lightGrayText.color
    ]

    // phone number start
    if let phoneNumber = coordinationDelegate?.verifiedPhoneNumber() {
      let formatter = CKPhoneNumberFormatter(kit: self.phoneNumberKit, format: .national)
      phoneVerificationStatusView.isHidden = false
      changeRemovePhoneButton.isHidden = false
      verifyPhoneNumberPrimaryButton.isHidden = true
      do {
        let identity = try formatter.string(from: phoneNumber)
        phoneVerificationStatusView.load(with: .phone, identityString: identity)
      } catch {
        phoneVerificationStatusView.load(with: .phone, identityString: phoneNumber.asE164())
      }
      setupAddressUI()
    } else {
      serverAddressView.isHidden = true
      addressButton.isHidden = true
      phoneVerificationStatusView.isHidden = true
      let verifyPhoneButtonTitle = NSAttributedString(
        imageName: "phoneDrawerIcon", 
        imageSize: CGSize(width: 13, height: 22),
        title: "VERIFY PHONE NUMBER", 
        textColor: Theme.Color.lightGrayText.color,
        font: Theme.Font.verificationActionTitle.font)
      verifyPhoneNumberPrimaryButton.setTitle(nil, for: .normal)
      verifyPhoneNumberPrimaryButton.setAttributedTitle(verifyPhoneButtonTitle, for: .normal)
      changeRemovePhoneButton.isHidden = true
      verifyPhoneNumberPrimaryButton.isHidden = false
    }
    // phone number end

    // twitter start
    if let handle = coordinationDelegate?.verifiedTwitterHandle() {
      twitterVerificationStatusView.isHidden = false
      changeRemoveTwitterButton.isHidden = false
      verifyTwitterPrimaryButton.isHidden = true
      twitterVerificationStatusView.load(with: .twitter, identityString: handle)
    } else {
      twitterVerificationStatusView.isHidden = true
      changeRemoveTwitterButton.isHidden = true
      verifyTwitterPrimaryButton.isHidden = false
      verifyTwitterPrimaryButton.setTitle(nil, for: .normal)

      let verifyTwitterButtonTitle = NSAttributedString(
        imageName: "twitterBird",
        imageSize: CGSize(width: 20, height: 16),
        title: "VERIFY TWITTER ACCOUNT",
        textColor: Theme.Color.lightGrayText.color,
        font: Theme.Font.verificationActionTitle.font)

      verifyTwitterPrimaryButton.setAttributedTitle(verifyTwitterButtonTitle, for: .normal)
    }
    // twitter end

    let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: Theme.Color.lightBlueTint.color,
                                                     .font: Theme.Font.serverAddressTitle.font,
                                                     .underlineStyle: 1,
                                                     .underlineColor: Theme.Color.lightBlueTint.color]

    let attributedString = NSAttributedString(string: "View DropBit addresses", attributes: attributes)
    addressButton.setAttributedTitle(attributedString, for: .normal)

    view.layoutIfNeeded()
  }

  private func setupAddressUI() {
    // Hide address elements if no addresses exist or words aren't backed up
    if let addresses = coordinationDelegate?.viewControllerDidRequestAddresses(),
      addresses.isNotEmpty {
      serverAddressView.addresses = addresses
      addressButton.isHidden = false
      serverAddressView.isHidden = false
    } else {
      addressButton.isHidden = true
      serverAddressView.isHidden = true
    }
  }

  private func fetchAddresses() {
    if let addresses = coordinationDelegate?.viewControllerDidRequestAddresses() {
      serverAddressView.addresses = addresses
    }
  }

  @IBAction func closeButtonWasTouched() {
    coordinationDelegate?.viewControllerDidSelectClose(self)
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
    coordinationDelegate?.viewControllerDidSelectVerifyPhone(self)
  }

  @IBAction func verifyTwitter() {
    coordinationDelegate?.viewControllerDidSelectVerifyTwitter(self)
  }

  @IBAction func changeRemovePhone() {
    coordinationDelegate?.viewControllerDidRequestToUnverifyPhone(self, successfulCompletion: { [weak self] in
      self?.setupUI()
    })
  }

  @IBAction func changeRemoveTwitter() {
    coordinationDelegate?.viewControllerDidRequestToUnverifyTwitter(self, successfulCompletion: { [weak self] in
      self?.setupUI()
    })
  }
}

extension PhoneNumberStatusViewController: ServerAddressViewDelegate {
  func didPressCloseButton() {
    UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
      self?.serverAddressBackgroundView.alpha = 0.0
      self?.serverAddressViewVerticalConstraint.constant = UIScreen.main.bounds.height
      self?.view.layoutIfNeeded()
    })
  }

  func didPressQuestionMarkButton() {
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .myAddressesTooltip) else { return }
    coordinationDelegate?.viewControllerDidRequestOpenURL(self, url: url)
  }
}
