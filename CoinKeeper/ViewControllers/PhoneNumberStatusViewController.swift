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

protocol PhoneNumberStatusViewControllerDelegate: class {
  func verifiedPhoneNumber() -> GlobalPhoneNumber?
  func viewControllerDidRequestAddresses() -> [ServerAddressViewModel]
  func viewControllerDidRequestOpenURL(_ viewController: UIViewController, url: URL)
  func viewControllerDidSelectVerifyPhone(_ viewController: UIViewController)
  func viewControllerDidRequestToUnverify(_ viewController: UIViewController, successfulCompletion: @escaping () -> Void)
}

class PhoneNumberStatusViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var serverAddressViewVerticalConstraint: NSLayoutConstraint!
  @IBOutlet var serverAddressView: ServerAddressView! {
    didSet {
      serverAddressView.delegate = self
    }
  }

  @IBOutlet var titleLabel: UILabel! {
    didSet {
      titleLabel.font = Theme.Font.phoneNumberStatusTitle.font
      titleLabel.textColor = Theme.Color.grayText.color
    }
  }

  @IBOutlet var serverAddressBackgroundView: UIView!

  @IBOutlet var phoneNumberNavigationTitle: UILabel! {
    didSet {
      phoneNumberNavigationTitle.font = Theme.Font.onboardingSubtitle.font
      phoneNumberNavigationTitle.textColor = Theme.Color.darkBlueText.color
    }
  }
  @IBOutlet var privacyLabel: UILabel! {
    didSet {
      privacyLabel.font = Theme.Font.phoneNumberStatusPrivacy.font
      privacyLabel.textColor = Theme.Color.darkBlueText.color
    }
  }
  @IBOutlet var verifyPhoneNumberPrimaryButton: PrimaryActionButton!
  @IBOutlet var changeRemoveButton: UIButton! {
    didSet {
      changeRemoveButton.setTitleColor(Theme.Color.errorRed.color, for: .normal)
      changeRemoveButton.titleLabel?.font = Theme.Font.removeNumberError.font
    }
  }
  @IBOutlet var unverifiedPhoneStackView: UIStackView!
  @IBOutlet var verifiedPhoneStackView: UIStackView!
  @IBOutlet var closeButton: UIButton!

  @IBOutlet var verifyPhoneNumberLabel: UILabel! {
    didSet {
      verifyPhoneNumberLabel.font = Theme.Font.phoneNumberStatusTitle.font
      verifyPhoneNumberLabel.textColor = Theme.Color.grayText.color
    }
  }

  @IBOutlet var phoneNumberLabel: UILabel! {
    didSet {
      phoneNumberLabel.font = Theme.Font.phoneNumberStatus.font
      phoneNumberLabel.textColor = Theme.Color.darkBlueText.color
    }
  }

  @IBOutlet var addressButton: UIButton! {
    didSet {
      let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: Theme.Color.lightBlueTint.color,
                                                       .font: Theme.Font.serverAddressTitle.font,
                                                       .underlineStyle: 1,
                                                       .underlineColor: Theme.Color.lightBlueTint.color]
      let attributedString = NSAttributedString(string: "View DropBit addresses", attributes: attributes)
      addressButton.setAttributedTitle(attributedString, for: .normal)
    }
  }

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
    serverAddressViewVerticalConstraint.constant = UIScreen.main.bounds.height

    if let phoneNumber = coordinationDelegate?.verifiedPhoneNumber() {
      unverifiedPhoneStackView.isHidden = true
      verifiedPhoneStackView.isHidden = false

      let formatter = CKPhoneNumberFormatter(kit: self.phoneNumberKit, format: .national)
      do {
        phoneNumberLabel.text = try formatter.string(from: phoneNumber)
      } catch {
        phoneNumberLabel.text = phoneNumber.asE164()
      }

      setupAddressUI()
    } else {
      serverAddressView.isHidden = true
      addressButton.isHidden = true
      unverifiedPhoneStackView.isHidden = false
      verifiedPhoneStackView.isHidden = true
    }
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
    dismiss(animated: true, completion: nil)
  }

  @IBAction func addressButtonWasTouched() {
    UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
      guard let strongSelf = self else { return }
      self?.serverAddressBackgroundView.alpha = 0.5
      self?.serverAddressViewVerticalConstraint.constant = UIScreen.main.bounds.height * strongSelf.serverAddressUpperPercentageMultiplier
      self?.view.layoutIfNeeded()
    })
  }

  @IBAction func verifyPhoneNumberPrimaryButtonWasTouched() {
    coordinationDelegate?.viewControllerDidSelectVerifyPhone(self)
  }

  @IBAction func changeRemoveButtonWasTouched() {
    coordinationDelegate?.viewControllerDidRequestToUnverify(self, successfulCompletion: { [weak self] in
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
