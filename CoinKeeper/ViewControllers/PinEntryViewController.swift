//
//  PinEntryViewController.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import Result

protocol PinEntryViewControllerDelegate: ViewControllerDismissable {
  func checkMatch(for digits: String) -> Bool
  func viewControllerDidTryBiometrics(_ pinEntryViewController: PinEntryViewController)
  func viewControllerDidSuccessfullyAuthenticate(_ pinEntryViewController: PinEntryViewController)
  func pinExists() -> Bool
  var biometricType: BiometricType { get }
}

final class PinEntryViewController: BaseViewController, StoryboardInitializable {

  /// A closure to be called when authentication succeeds
  var whenAuthenticated: (() -> Void)?

  enum Mode {
    case standard
    case inviteVerification(completion: (Result<Bool, PinValidationError>) -> Void)
    case paymentVerification(amountDisablesBiometrics: Bool, completion: (Result<Bool, PinValidationError>) -> Void)
    case walletDeletion(completion: (Result<Bool, PinValidationError>) -> Void)
    case recoveryWords(completion: (Result<Bool, PinValidationError>) -> Void)
  }

  private var shouldAttemptToUseBiometrics: Bool {
    guard let delegate = coordinationDelegate, delegate.pinExists() else { return false }
    switch mode {
    case .recoveryWords, .walletDeletion:
      return false
    case .paymentVerification(let shouldDisableBiometrics, _):
      if shouldDisableBiometrics {
        return false
      } else {
        return true
      }
    default:
      return true
    }
  }

  var mode: Mode = .standard

  // MARK: outlets
  @IBOutlet var keypadEntryView: KeypadEntryView! {
    didSet {
      keypadEntryView.alpha = 0
      keypadEntryView.delegate = self
      keypadEntryView.entryMode = .pin
    }
  }
  @IBOutlet var securePinDisplayView: SecurePinDisplayView! {
    didSet {
      securePinDisplayView.alpha = 0
    }
  }
  @IBOutlet var logoImage: UIImageView! {
    didSet {
      switch mode {
      case .standard, .walletDeletion, .recoveryWords:
        logoImage.alpha = 1.0
      default:
        logoImage.alpha = 0.0
      }
    }
  }
  @IBOutlet var logoImageCenterYConstraint: NSLayoutConstraint!
  @IBOutlet var logoImageTopConstraint: NSLayoutConstraint!
  @IBOutlet var stackContainerView: UIView! {
    didSet {
      stackContainerView.alpha = 0.0
    }
  }
  @IBOutlet var biometricButton: UIButton! {
    didSet {
      biometricButton.setTitle(nil, for: .normal)
      biometricButton.alpha = 0
    }
  }

  @IBOutlet var pinConfirmLabel: UILabel! {
    didSet {
      switch mode {
      case .standard:
        pinConfirmLabel.alpha = 0.0
      case .recoveryWords:
        pinConfirmLabel.text = "Enter pin to unlock recovery words"
      case .walletDeletion:
        pinConfirmLabel.alpha = 0.0
        pinConfirmLabel.text = "Enter pin to confirm deletion of your wallet"
      default:
        pinConfirmLabel.alpha = 1.0
      }

      pinConfirmLabel.textColor = .darkGrayText
      pinConfirmLabel.font = .regular(15)
    }
  }

  @IBOutlet var closeButton: UIButton! {
    didSet {
      switch mode {
      case .standard:
        closeButton.alpha = 0.0
      default:
        closeButton.alpha = 1.0
      }
    }
  }

  @IBOutlet var errorLabel: UILabel! {
    didSet {
      errorLabel.textColor = .darkPeach
      errorLabel.font = .regular(15)
      self.resetErrorLabel()
    }
  }
  @IBOutlet var lockoutBlurView: UIVisualEffectView! {
    didSet {
      lockoutBlurView.alpha = 0
      lockoutBlurView.isHidden = false
    }
  }
  @IBOutlet var lockoutErrorLabel: UILabel! {
    didSet {
      lockoutErrorLabel.font = .regular(15)
      lockoutErrorLabel.textColor = .whiteText
      lockoutErrorLabel.text = "Too many incorrect attempts. Please wait 5 minutes and try entering your PIN again."
    }
  }

  // MARK: variables
  var coordinationDelegate: PinEntryViewControllerDelegate? {
    return generalCoordinationDelegate as? PinEntryViewControllerDelegate
  }
  var pinVerifyDelegate: PinVerificationDelegate? {
    return generalCoordinationDelegate as? PinVerificationDelegate
  }
  var digitEntryDisplayViewModel: DigitEntryDisplayViewModelType!
  let logoConstraintMultiplier: CGFloat = 3

  private var failureCount = 0
  private let maxFailureCount = 6
  private var timer: Timer?

  // MARK: view lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    initialize()
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (view, .pinEntry(.page))
    ]
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    performInitialAnimations()
    if let delegate = pinVerifyDelegate, delegate.viewControllerShouldAllowPinEntry() {
      tryBiometrics()
    }
  }

  deinit {
    stopTimer()
  }

  // MARK: IBActions
  @IBAction func closeButtonWasTouched() {
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }

  @IBAction func biometricButtonTapped(_ sender: UIButton) {
    if let delegate = pinVerifyDelegate, delegate.viewControllerShouldAllowPinEntry() {
      tryBiometrics()
    }
  }

  // MARK: methods
  private func initialize() {
    setupBiometricButton()
    digitEntryDisplayViewModel = DigitEntryDisplayViewModel(view: securePinDisplayView)
    if let delegate = pinVerifyDelegate, !delegate.viewControllerShouldAllowPinEntry() {
      animateLockoutView(show: true)
    }
  }

  private func startTimer() {
    guard timer == nil else { return }
    timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: timerHandler)
  }

  private func stopTimer() {
    timer?.invalidate()
    timer = nil
  }

  private func timerHandler(_ timer: Timer) {
    guard let pinVerifyDelegate = pinVerifyDelegate else { return }
    let shouldAllow = pinVerifyDelegate.viewControllerShouldAllowPinEntry()

    animateLockoutView(show: !shouldAllow)

    if shouldAllow {
      resetErrorLabel()
      stopTimer()
      tryBiometrics()
    }
  }

  func setupBiometricButton() {
    guard let biometricType = coordinationDelegate?.biometricType else { return }
    var image: UIImage?
    switch biometricType {
    case .faceID: image = UIImage(named: "faceID")
    case .touchID: image = UIImage(named: "touchID")
    default: image = nil
    }
    biometricButton.setImage(image, for: .normal)
  }

  func tryBiometrics() {
    if shouldAttemptToUseBiometrics {
      coordinationDelegate?.viewControllerDidTryBiometrics(self)
    }
  }

  func performInitialAnimations() {
    view.layoutIfNeeded()

    UIView.animateKeyframes(withDuration: 1.25, delay: 0.25, options: .calculationModeCubicPaced, animations: {
      UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) { [weak self] in
        guard let strongSelf = self else { return }
        let distance: CGFloat = strongSelf.view.frame.height < 600 ? 0 : 22
        strongSelf.logoImageCenterYConstraint.isActive = false
        strongSelf.logoImageTopConstraint.isActive = true
        strongSelf.logoImageTopConstraint.constant = distance
        strongSelf.view.layoutIfNeeded()
      }
      UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) { [weak self] in
        guard let strongSelf = self else { return }
        strongSelf.keypadEntryView.alpha = 1
        if strongSelf.shouldAttemptToUseBiometrics {
          strongSelf.biometricButton.alpha = 1
        }
        strongSelf.securePinDisplayView.alpha = 1
        strongSelf.stackContainerView.alpha = 1

        switch strongSelf.mode {
        case .walletDeletion:
          strongSelf.pinConfirmLabel.alpha = 1
        default:
          break
        }

        strongSelf.view.layoutIfNeeded()
      }
    })
  }

  private func resetErrorLabel() {
    errorLabel?.alpha = 0.0
    errorLabel?.text = "Incorrect PIN. Please try again."
  }

  private func handleLockoutIfNecessary() {
    guard failureCount == maxFailureCount else {
      errorLabel.alpha = 1.0
      return
    }
    pinVerifyDelegate?.viewControllerPinFailureCountExceeded(self)
    failureCount = 0

    animateLockoutView(show: true)

    startTimer()
  }

  private func animateLockoutView(show: Bool) {
    view.layoutIfNeeded()

    UIView.animate(
    withDuration: 0.3) {
      self.lockoutBlurView.alpha = show ? 1.0 : 0.0
      self.view.layoutIfNeeded()
    }
  }
}

extension PinEntryViewController: KeypadEntryViewDelegate {
  func selected(digit: String) {
    let addDigitResult = digitEntryDisplayViewModel.add(digit: digit)
    resetErrorLabel()
    guard addDigitResult == .complete, let delegate = coordinationDelegate else { return }
    if delegate.checkMatch(for: digitEntryDisplayViewModel.digits) {
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
        delegate.viewControllerDidSuccessfullyAuthenticate(self)
      }
    } else {
      failureCount += 1
      digitEntryDisplayViewModel.removeAllDigits()
      handleLockoutIfNecessary()
    }
  }

  func selectedBack() {
    digitEntryDisplayViewModel.removeDigit()
  }
}
