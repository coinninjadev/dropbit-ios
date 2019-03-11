//
//  DeviceVerificationViewController.swift
//  CoinKeeper
//
//  Created by Bill Feth on 4/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit
import SVProgressHUD
import UIKit
import os.log

protocol DeviceVerificationViewControllerDelegate: AnyObject {
  func viewController(_ viewController: DeviceVerificationViewController, didEnterPhoneNumber phoneNumber: GlobalPhoneNumber)
  func viewController(_ codeEntryViewController: DeviceVerificationViewController, didEnterCode code: String, completion: @escaping (Bool) -> Void)
  func viewControllerDidRequestResendCode(_ viewController: DeviceVerificationViewController)
  func viewControllerDidSkipPhoneVerification(_ viewController: DeviceVerificationViewController)
  func viewControllerShouldShowSkipButton() -> Bool
}

enum DeviceVerificationError {
  case codeFailureLimitExceeded
  case incorrectCode
  case invalidPhoneNumber //failed local parsing

  var displayMessage: String {
    switch self {
    case .codeFailureLimitExceeded:
      return "Incorrect code entered 3 times.\nPlease re-enter your phone number to try again."
    case .incorrectCode:
      return "Incorrect code.\nPlease try again."
    case .invalidPhoneNumber:
      return "Invalid phone number. Please make sure you have entered the correct number."
    }
  }
}

final class DeviceVerificationViewController: BaseViewController {

  enum Mode {
    case phoneNumberEntry
    case codeVerification(GlobalPhoneNumber)
    case codeVerificationFailed
    case codeFailureCountExceeded
  }

  @IBOutlet var keypadEntryView: KeypadEntryView! {
    didSet {
      keypadEntryView.entryMode = .pin
      keypadEntryView.delegate = self
    }
  }
  @IBOutlet var titleLabel: OnboardingTitleLabel!
  @IBOutlet var subtitleLabel: OnboardingSubtitleLabel!
  @IBOutlet var errorLabel: OnboardingErrorLabel! {
    didSet {
      errorLabel.text = DeviceVerificationError.codeFailureLimitExceeded.displayMessage
    }
  }

  @IBOutlet var exampleLabel: ExamplePhoneNumberLabel!
  @IBOutlet var phoneNumberContainer: UIView!
  @IBOutlet var phoneNumberEntryView: PhoneNumberEntryView!
  @IBOutlet var submitPhoneNumberButton: PrimaryActionButton!
  @IBOutlet var codeDisplayView: PinDisplayView!
  @IBOutlet var resendCodeButton: UnderlinedTextButton!

  var countryCodeSearchView: CountryCodeSearchView?
  let countryCodeDataSource = CountryCodePickerDataSource()
  let phoneNumberKit = PhoneNumberKit()

  @IBAction func resendTextMessage(_ sender: Any) {
    coordinationDelegate?.viewControllerDidRequestResendCode(self)
  }
  @IBAction func submitPhoneNumber(_ sender: Any) {
    
  }

  @objc func skipVerification() {
    coordinationDelegate?.viewControllerDidSkipPhoneVerification(self)
  }

  // MARK: variables
  var coordinationDelegate: DeviceVerificationViewControllerDelegate? {
    return generalCoordinationDelegate as? DeviceVerificationViewControllerDelegate
  }
  var entryMode: DeviceVerificationViewController.Mode = .phoneNumberEntry {
    didSet {
      updateUI()
    }
  }
  var digitEntryViewModel: DigitEntryDisplayViewModelType?

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .deviceVerification(.page)) //skipButton is not available when this is called
    ]
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    digitEntryViewModel = DigitEntryDisplayViewModel(view: codeDisplayView, maxDigits: 6)
    updateUI()
    setupPhoneNumberEntryView(textFieldEnabled: false)
  }

  var shouldOrphan: Bool = false

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    digitEntryViewModel?.removeAllDigits()
    navigationController?.isNavigationBarHidden = false

    if shouldOrphan {
      navigationController?.orphanDisplayingViewController()
    }
  }

  private func updateUI() {
    guard viewIfLoaded != nil else { return } // Guard against nil outlets when updateUI() is called as a side-effect of setting entryMode
    let enterYourPhone = NSLocalizedString("Phone Number", comment: "Phone Number")
    //swiftlint:disable line_length
    let normalPhoneMessage = NSLocalizedString("Please enter your phone number below to use the \(CKStrings.dropBitWithTrademark) feature. DropBit allows you to send Bitcoin directly to your contacts by using their mobile number.", comment: "Please enter your phone number below to use the \(CKStrings.dropBitWithTrademark) feature. DropBit allows you to send Bitcoin directly to your contacts by using their mobile number.")
    let enterYourCode = NSLocalizedString("Verification Code", comment: "Verification Code")
    let retryMessage = NSLocalizedString("We just sent you a 6 digit\nverification code.", comment: "We just sent you a 6 digit\nverification code.")

    // Hide these views by default, then selectively show them
    setDefaultHiddenViews()

    configureResendCodeButton()
    configureNavButton()

    keypadEntryView.delegate = self

    switch entryMode {
    case .phoneNumberEntry:
      updatePrimaryLabels(title: enterYourPhone, message: normalPhoneMessage)

      submitPhoneNumberButton.setTitle("NEXT", for: .normal)
      updateView(forSelectedRegion: phoneNumberEntryView.selectedRegion)
      exampleLabel.isHidden = false
      phoneNumberContainer.isHidden = false
      phoneNumberEntryView.isHidden = false
      keypadEntryView.delegate = self.phoneNumberEntryView.textField

    case .codeVerification(let phoneNumber):
      updatePrimaryLabels(title: enterYourCode, message: normalCodeMessage(with: phoneNumber))
      codeDisplayView.isHidden = false

    case .codeVerificationFailed:
      updatePrimaryLabels(title: enterYourCode, message: retryMessage)
      updateErrorLabel(with: DeviceVerificationError.incorrectCode.displayMessage)
      codeDisplayView.isHidden = false

    case .codeFailureCountExceeded:
      updatePrimaryLabels(title: enterYourPhone, message: normalPhoneMessage)
      updateErrorLabel(with: DeviceVerificationError.codeFailureLimitExceeded.displayMessage)
      phoneNumberEntryView.isHidden = false
    }
  }

  private func updatePrimaryLabels(title: String, message: String) {
    titleLabel?.text = title
    subtitleLabel?.text = message
  }

  func updateErrorLabel(with message: String?) {
    errorLabel?.text = message
    errorLabel?.isHidden = (message == nil)
  }

  private func setDefaultHiddenViews() {
    exampleLabel.isHidden = true
    phoneNumberContainer.isHidden = true
    phoneNumberEntryView.isHidden = true
    submitPhoneNumberButton.isHidden = true
    codeDisplayView.isHidden = true
    updateErrorLabel(with: nil)
  }

  /// Returns String instead of NSLocalizedString because Xcode threw a compiler error: Use of undeclared type NSLocalizedString (??)
  private func normalCodeMessage(with phoneNumber: GlobalPhoneNumber) -> String {
    let kit = self.phoneNumberKit
    let formatter = CKPhoneNumberFormatter(kit: kit, format: .national)

    let formattedNumber: String = (try? formatter.string(from: phoneNumber)) ?? phoneNumber.asE164()

    return "We’ve sent a six digit verification \ncode to \(formattedNumber). It may take \nup to 30 seconds to receive the text."
  }

  private func configureNavButton() {
    guard let shouldShowSkipButton = coordinationDelegate?.viewControllerShouldShowSkipButton(), shouldShowSkipButton else {
      self.navigationItem.rightBarButtonItem = nil
      return
    }

    let buttonItem = BarButtonFactory.skipButton(withTarget: self, selector: #selector(skipVerification))
    buttonItem.setAccessibilityId(.deviceVerification(.skipButton))
    self.navigationItem.rightBarButtonItem = buttonItem
  }

  private func configureResendCodeButton() {
    switch entryMode {
    case .codeVerification, .codeVerificationFailed:
      resendCodeButton.isHidden = false
      resendCodeButton.setUnderlinedTitle("Resend Text Message", size: 14, color: Theme.Color.darkBlueText.color)

    case .phoneNumberEntry, .codeFailureCountExceeded:
      resendCodeButton.isHidden = true
    }
  }

}

extension DeviceVerificationViewController: PhoneNumberEntryViewDisplayable {

  func phoneNumberEntryView(_ view: PhoneNumberEntryView, didSelectCountry country: CKCountry) {
    updateView(forSelectedRegion: country.regionCode)
  }

  private func updateView(forSelectedRegion regionCode: String) {
    switch entryMode {
    case .phoneNumberEntry:

      let formatter = CKPhoneNumberFormatter(kit: self.phoneNumberKit, format: .national)
      let exampleNumber = self.phoneNumberKit.exampleNumber(forCountry: regionCode, phoneNumberType: .mobile)
      let countryCode = self.phoneNumberEntryView.textField.currentGlobalNumber().countryCode

      // concatenate country code with formatted national number to match parentheses formatting of CKPhoneNumberTextField for US
      if let nationalNumber = exampleNumber,
        let formattedNationalNumber = try? formatter.string(from: GlobalPhoneNumber(countryCode: countryCode, nationalNumber: nationalNumber)) {
        exampleLabel.text = "Example: +\(countryCode) \(formattedNationalNumber)"

      } else {
        exampleLabel.text = nil
      }

      let phoneNumberLengths = self.phoneNumberKit.possiblePhoneNumberLengths(forCountry: regionCode, phoneNumberType: .mobile, lengthType: .national)
      let regionHasSinglePhoneNumberLength = phoneNumberLengths.count == 1
      submitPhoneNumberButton.isHidden = regionHasSinglePhoneNumberLength

    default:
      break
    }
  }
}

extension DeviceVerificationViewController: StoryboardInitializable {}

extension DeviceVerificationViewController: KeypadEntryViewDelegate {

  private func resetErrorIfNeeded() {
    errorLabel?.isHidden = true
    switch entryMode {
    case .codeFailureCountExceeded: entryMode = .phoneNumberEntry
    default: break
    }
  }

  func selected(digit: String) {
    resetErrorIfNeeded()

    let addDigitResult = digitEntryViewModel?.add(digit: digit)
    guard addDigitResult == .complete else { return }
    guard let coordinationDelegate = coordinationDelegate else { return }

    switch entryMode {
    case .codeVerification, .codeVerificationFailed:
      let codeString = digitEntryViewModel?.digits
      coordinationDelegate.viewController(self, didEnterCode: codeString!) { [weak self] (success) in
        if !success {
          self?.digitEntryViewModel?.removeAllDigits()
        }
      }

    case .codeFailureCountExceeded:
      let logger = OSLog(subsystem: "com.coinninja.coinkeeper.deviceverificationviewcontroller", category: "device_verification_view_controller")
      os_log("Devide verification failed three times", log: logger, type: .error)

    case .phoneNumberEntry:
      break
    }
  }

  func selectedBack() {
    digitEntryViewModel?.removeDigit()
  }

}

extension DeviceVerificationViewController: CKPhoneNumberTextFieldDelegate {

  func textFieldReceivedValidMobileNumber(_ phoneNumber: GlobalPhoneNumber, textField: CKPhoneNumberTextField) {
    self.updateErrorLabel(with: nil)
    self.coordinationDelegate?.viewController(self, didEnterPhoneNumber: phoneNumber)
  }

  func textFieldReceivedInvalidMobileNumber(_ phoneNumber: GlobalPhoneNumber, textField: CKPhoneNumberTextField) {
    self.updateErrorLabel(with: DeviceVerificationError.invalidPhoneNumber.displayMessage)
  }

}
