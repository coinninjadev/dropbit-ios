//
//  PinCreationViewController.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol PinCreationViewControllerDelegate: AnyObject {
  func viewControllerFullyEnteredPin(_ viewController: PinCreationViewController, digits: String)
}

protocol PinVerificationDelegate: AnyObject {
  func pinWasVerified(digits: String, for flow: PinCreationViewController.Flow)
  func viewControllerPinFailureCountExceeded(_ viewController: UIViewController)
  func viewControllerShouldAllowPinEntry() -> Bool
}

extension PinVerificationDelegate {
  func viewControllerShouldAllowPinEntry() -> Bool {
    return true
  }
}

final class PinCreationViewController: BaseViewController {

  enum Mode {
    case pinEntry
    case pinVerification(digits: String)
    case pinVerificationFailed
  }

  enum Flow {
    case creation
    case restore
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
      errorLabel.text = "Incorrect PIN entered 3 times.\nPlease create a new PIN."
    }
  }
  @IBOutlet var securePinDisplayView: SecurePinDisplayView!

  var flow: Flow = .creation

  // MARK: variables
  var coordinationDelegate: PinCreationViewControllerDelegate? {
    return generalCoordinationDelegate as? PinCreationViewControllerDelegate
  }
  weak var verificationDelegate: PinVerificationDelegate?
  var entryMode: PinCreationViewController.Mode = .pinEntry {
    didSet {
      updateUI()
    }
  }
  var digitEntryDisplayViewModel: DigitEntryDisplayViewModelType!

  // MARK: private var
  private var failureCount = 0
  private let maxFailures = 3

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .pinCreation(.page))
    ]
  }
  override func viewDidLoad() {
    super.viewDidLoad()

    digitEntryDisplayViewModel = DigitEntryDisplayViewModel(view: securePinDisplayView)
    updateUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    digitEntryDisplayViewModel.removeAllDigits()
  }

  private func updateUI() {
    let normalMessage = "Your PIN will be used to access\nDropBit and send Bitcoin"
    let setYourPin = "Set Your PIN"
    let reenterYourPin = "Re-Enter PIN"
    let errorMessage = "Incorrect PIN entered 3 times.\nPlease create a new PIN."
    switch entryMode {
    case .pinEntry:
      titleLabel?.text = setYourPin
      subtitleLabel?.text = normalMessage
      errorLabel?.isHidden = true
    case .pinVerification(digits: _):
      titleLabel?.text = reenterYourPin
      subtitleLabel?.text = normalMessage
      errorLabel?.isHidden = true
    case .pinVerificationFailed:
      errorLabel?.isHidden = false
      titleLabel?.text = setYourPin
      subtitleLabel?.text = normalMessage
      errorLabel?.text = errorMessage
    }
  }
}

extension PinCreationViewController: StoryboardInitializable {}

extension PinCreationViewController: KeypadEntryViewDelegate {
  private func resetErrorIfNeeded() {
    errorLabel?.isHidden = true
    switch entryMode {
    case .pinVerificationFailed: entryMode = .pinEntry
    default: break
    }
  }

  func selected(digit: String) {
    resetErrorIfNeeded()
    let result = digitEntryDisplayViewModel.add(digit: digit)
    guard result == .complete else { return }
    switch entryMode {
    case .pinEntry: coordinationDelegate?.viewControllerFullyEnteredPin(self, digits: digitEntryDisplayViewModel.digits)
    case .pinVerification(let previousDigits):
      if digitEntryDisplayViewModel.digits == previousDigits {
        verificationDelegate?.pinWasVerified(digits: previousDigits, for: flow)
      } else {
        handleVerificationFailure()
      }
    case .pinVerificationFailed: break
    }
  }

  private func handleVerificationFailure() {
    failureCount += 1
    guard failureCount < maxFailures else {
      verificationDelegate?.viewControllerPinFailureCountExceeded(self)
      return
    }
    errorLabel.text = "Incorrect PIN.\nPlease try again."
    errorLabel.isHidden = false
    digitEntryDisplayViewModel.removeAllDigits()
  }

  func selectedBack() {
    digitEntryDisplayViewModel.removeDigit()
  }
}

extension PinCreationViewController.Mode: Equatable {
  static func == (lhs: PinCreationViewController.Mode, rhs: PinCreationViewController.Mode) -> Bool {
    switch (lhs, rhs) {
    case (.pinEntry, .pinEntry): return true
    case (.pinVerification(let leftDigits), .pinVerification(let rightDigits)): return leftDigits == rightDigits
    case (.pinVerificationFailed, .pinVerificationFailed): return true
    default: return false
    }
  }
}
