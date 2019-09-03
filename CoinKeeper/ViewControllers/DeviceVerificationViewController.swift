//
//  DeviceVerificationViewController.swift
//  DropBit
//
//  Created by Bill Feth on 4/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import SVProgressHUD
import UIKit

protocol DeviceVerificationViewControllerDelegate: AnyObject {
  func viewController(_ viewController: DeviceVerificationViewController, didEnterPhoneNumber phoneNumber: GlobalPhoneNumber)
  func viewController(_ codeEntryViewController: DeviceVerificationViewController,
                      didEnterCode code: String,
                      forUserId userId: String,
                      completion: @escaping (Bool) -> Void)
  func viewControllerDidRequestResendCode(_ viewController: DeviceVerificationViewController)
  func viewControllerDidSkipPhoneVerification(_ viewController: DeviceVerificationViewController)
  func viewControllerShouldShowSkipButton() -> Bool
  func viewControllerDidSelectVerifyTwitter(_ viewController: UIViewController)
}

enum DeviceVerificationError: Error {
  case codeFailureLimitExceeded
  case incorrectCode
  case invalidPhoneNumber //failed local parsing
  case missingTwitterIdentity

  var displayMessage: String {
    switch self {
    case .codeFailureLimitExceeded:
      return "Incorrect code entered 3 times.\nPlease re-enter your phone number to try again."
    case .incorrectCode:
      return "Incorrect code.\nPlease try again."
    case .invalidPhoneNumber:
      return "Invalid phone number. Please make sure you have entered the correct number."
    case .missingTwitterIdentity:
      return "Missing Twitter verification. Please authorize DropBit to use Twitter as an authentication mechanism."
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
  @IBOutlet var oneTimeCodeInputTextField: UITextField! {
    didSet {
      if #available(iOS 12.0, *) {
        oneTimeCodeInputTextField.isHidden = true
        oneTimeCodeInputTextField.textContentType = .oneTimeCode
        oneTimeCodeInputTextField.delegate = self
        oneTimeCodeInputTextField.keyboardType = .numberPad
      }
    }
  }

  @IBOutlet var orView: UIView!
  @IBOutlet var orLeftLineView: UIView!
  @IBOutlet var orLabel: UILabel!
  @IBOutlet var orRightLineView: UIView!
  @IBOutlet var twitterButton: PrimaryActionButton!

  @IBAction func verifyTwitter(_ sender: Any) {
    coordinationDelegate?.viewControllerDidSelectVerifyTwitter(self)
  }

  @IBAction func resendTextMessage(_ sender: Any) {
    coordinationDelegate?.viewControllerDidRequestResendCode(self)
  }

  @IBAction func submitPhoneNumber(_ sender: Any) {
    let phoneNumber = phoneNumberEntryView.textField.currentGlobalNumber()

    do {
      let parsedNumber = try phoneNumberKit.parse(phoneNumber.asE164())
      let globalNumber = GlobalPhoneNumber(parsedNumber: parsedNumber,
                                           regionCode: phoneNumberEntryView.selectedRegion)
      self.handleValidPhoneNumber(globalNumber)

    } catch {
      self.handleInvalidPhoneNumber()
    }
  }

  @objc func skipVerification() {
    coordinationDelegate?.viewControllerDidSkipPhoneVerification(self)
  }

  // MARK: variables

  var selectedSetupFlow: SetupFlow?
  var userIdToVerify: String?

  var shouldShowTwitterButton: Bool {
    guard let selectedFlow = selectedSetupFlow else { return false }
    switch selectedFlow {
    case .newWallet, .restoreWallet:  return true
    case .claimInvite:                return false
    }
  }

  var countryCodeSearchView: CountryCodeSearchView?
  let countryCodeDataSource = CountryCodePickerDataSource()

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

  static func newInstance(delegate: DeviceVerificationViewControllerDelegate,
                          entryMode: Mode,
                          setupFlow: SetupFlow?,
                          userIdToVerify: String? = nil,
                          shouldOrphan: Bool = false) -> DeviceVerificationViewController {
    let vc = DeviceVerificationViewController.makeFromStoryboard()
    vc.entryMode = entryMode
    vc.selectedSetupFlow = setupFlow
    vc.userIdToVerify = userIdToVerify
    vc.shouldOrphan = shouldOrphan
    vc.generalCoordinationDelegate = delegate
    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    digitEntryViewModel = DigitEntryDisplayViewModel(view: codeDisplayView, maxDigits: 6)
    configureTwitterViews()
    updateUI()
    setupPhoneNumberEntryView(textFieldEnabled: false)

    if #available(iOS 12.0, *) {
      switch entryMode {
      case .phoneNumberEntry: break
      case .codeFailureCountExceeded, .codeVerification, .codeVerificationFailed:
        keypadEntryView.alpha = 0.0
        oneTimeCodeInputTextField.becomeFirstResponder()
      }
    }
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
      showTwitterViews(self.shouldShowTwitterButton)

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

  private func showTwitterViews(_ shouldShow: Bool) {
    orView.isHidden = !shouldShow
    twitterButton.isHidden = !shouldShow
  }

  private func configureTwitterViews() {
    let twitterBlue = UIColor.lightBlueTint
    orLeftLineView.backgroundColor = twitterBlue
    orRightLineView.backgroundColor = twitterBlue
    orLabel.textColor = twitterBlue
    orLabel.text = "OR"
    orLabel.font = .primaryButtonTitle
    twitterButton.style = .standard

    let twitterTitle = NSAttributedString(imageName: "twitterBird",
                                          imageSize: CGSize(width: 20, height: 17),
                                          title: "VERIFY TWITTER ACCOUNT",
                                          sharedColor: .lightGrayText,
                                          font: .primaryButtonTitle)
    twitterButton.setAttributedTitle(twitterTitle, for: .normal)
  }

  private func updatePrimaryLabels(title: String, message: String) {
    titleLabel?.text = title
    subtitleLabel?.text = message
  }

  func updateErrorLabel(with message: String?) {
    errorLabel?.text = message
    errorLabel?.isHidden = (message == nil)
  }

  func handleValidPhoneNumber(_ phoneNumber: GlobalPhoneNumber) {
    self.updateErrorLabel(with: nil)
    self.coordinationDelegate?.viewController(self, didEnterPhoneNumber: phoneNumber)
  }

  func handleInvalidPhoneNumber() {
    self.updateErrorLabel(with: DeviceVerificationError.invalidPhoneNumber.displayMessage)
  }

  private func setDefaultHiddenViews() {
    orView.isHidden = true
    twitterButton.isHidden = true
    oneTimeCodeInputTextField.isHidden = true
    exampleLabel.isHidden = true
    phoneNumberContainer.isHidden = true
    phoneNumberEntryView.isHidden = true
    submitPhoneNumberButton.isHidden = true
    codeDisplayView.isHidden = true
    updateErrorLabel(with: nil)
  }

  /// Returns String instead of NSLocalizedString because Xcode threw a compiler error: Use of undeclared type NSLocalizedString (??)
  private func normalCodeMessage(with phoneNumber: GlobalPhoneNumber) -> String {
    let formatter = CKPhoneNumberFormatter(format: .national)

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
      resendCodeButton.setUnderlinedTitle("Resend Text Message", size: 14, color: .darkBlueText)

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

      let formatter = CKPhoneNumberFormatter(format: .international)
      let exampleNumber = phoneNumberKit.exampleNumber(forCountry: regionCode, phoneNumberType: .mobile)
      let countryCode = self.phoneNumberEntryView.textField.currentGlobalNumber().countryCode

      if let nationalNumber = exampleNumber,
        let formattedNumber = try? formatter.string(from: GlobalPhoneNumber(countryCode: countryCode, nationalNumber: nationalNumber)) {
        exampleLabel.text = "Example: \(formattedNumber)"

      } else {
        exampleLabel.text = nil
      }

      let phoneNumberLengths = phoneNumberKit.possiblePhoneNumberLengths(forCountry: regionCode, phoneNumberType: .mobile, lengthType: .national)
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
      guard let codeString = digitEntryViewModel?.digits, let userId = self.userIdToVerify else {
        log.error("Verification code or user ID is missing")
        return
      }

      coordinationDelegate.viewController(self, didEnterCode: codeString, forUserId: userId) { [weak self] (success) in
        if !success {
          self?.digitEntryViewModel?.removeAllDigits()
        }
      }

    case .codeFailureCountExceeded:
      log.warn("Device verification failed three times")

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
    handleValidPhoneNumber(phoneNumber)
  }

  func textFieldReceivedInvalidMobileNumber(_ phoneNumber: GlobalPhoneNumber, textField: CKPhoneNumberTextField) {
    handleInvalidPhoneNumber()
  }

}

extension DeviceVerificationViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if string.isEmpty {
      selectedBack()
    } else {
      selected(digit: string)
    }
    return true
  }
}
