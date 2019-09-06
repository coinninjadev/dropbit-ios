//
//  PinEntryViewController.swift
//  DropBit
//
//  Created by BJ Miller on 2/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import Result

protocol PinEntryViewControllerDelegate: ViewControllerDismissable {
  func checkMatch(for digits: String) -> Bool
  func viewControllerDidTryBiometrics(_ pinEntryViewController: PinEntryViewController)
  func viewControllerDidSuccessfullyAuthenticate(_ pinEntryViewController: PinEntryViewController, completion: CKCompletion?)
  func pinExists() -> Bool
  var biometricType: BiometricType { get }
}

final class PinEntryViewController: BaseViewController, StoryboardInitializable {

  private var successHandler: CKCompletion?

  static func newInstance(delegate: PinEntryViewControllerDelegate,
                          viewModel: PinEntryViewModel,
                          success: CKCompletion?) -> PinEntryViewController {
    let vc = PinEntryViewController.makeFromStoryboard()
    vc.delegate = delegate
    vc.viewModel = viewModel
    vc.successHandler = success
    return vc
  }

  private var shouldAttemptToUseBiometrics: Bool {
    guard delegate.pinExists() else { return false }
    return viewModel.shouldEnableBiometrics
  }

  // MARK: outlets
  @IBOutlet var keypadEntryView: KeypadEntryView!
  @IBOutlet var securePinDisplayView: SecurePinDisplayView!
  @IBOutlet var logoImage: UIImageView!
  @IBOutlet var logoImageCenterYConstraint: NSLayoutConstraint!
  @IBOutlet var logoImageTopConstraint: NSLayoutConstraint!
  @IBOutlet var stackContainerView: UIView!
  @IBOutlet var biometricButton: UIButton!
  @IBOutlet var messageLabel: UILabel!
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var errorLabel: UILabel!
  @IBOutlet var lockoutBlurView: UIVisualEffectView!
  @IBOutlet var lockoutErrorLabel: UILabel!

  // MARK: variables
  fileprivate weak var delegate: PinEntryViewControllerDelegate!
  var pinVerifyDelegate: PinVerificationDelegate? {
    return delegate as? PinVerificationDelegate
  }

  var viewModel: PinEntryViewModel!
  var digitEntryDisplayViewModel: DigitEntryDisplayViewModelType!
  let logoConstraintMultiplier: CGFloat = 3

  private var failureCount = 0
  private let maxFailureCount = 6
  private var timer: Timer?

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (view, .pinEntry(.page))
    ]
  }

  // MARK: view lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    setupView()
    loadViewModel()
    setupBiometricButton()
    digitEntryDisplayViewModel = DigitEntryDisplayViewModel(view: securePinDisplayView)
    if let delegate = pinVerifyDelegate, !delegate.viewControllerShouldAllowPinEntry() {
      animateLockoutView(show: true)
    }
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
    delegate.viewControllerDidSelectClose(self)
  }

  @IBAction func biometricButtonTapped(_ sender: UIButton) {
    if let delegate = pinVerifyDelegate, delegate.viewControllerShouldAllowPinEntry() {
      tryBiometrics()
    }
  }

  // MARK: methods

  private func setupView() {
    keypadEntryView.alpha = 0
    keypadEntryView.delegate = self
    keypadEntryView.entryMode = .pin

    securePinDisplayView.alpha = 0

    stackContainerView.alpha = 0.0

    biometricButton.setTitle(nil, for: .normal)
    biometricButton.alpha = 0

    messageLabel.textColor = .darkGrayText
    messageLabel.font = .regular(15)

    errorLabel.textColor = .darkPeach
    errorLabel.font = .regular(15)
    self.resetErrorLabel()

    lockoutBlurView.alpha = 0
    lockoutBlurView.isHidden = false

    lockoutErrorLabel.font = .regular(15)
    lockoutErrorLabel.textColor = .whiteText
    lockoutErrorLabel.text = "Too many incorrect attempts. Please wait 5 minutes and try entering your PIN again."
  }

  func loadViewModel() {
    closeButton.isHidden = !viewModel.shouldShowCloseButton
    closeButton.isEnabled = viewModel.shouldShowCloseButton
    logoImage.alpha = viewModel.shouldShowLogo ? 1.0 : 0.0
    messageLabel.alpha = viewModel.shouldAnimateMessage ? 0.0 : 1.0
    messageLabel.text = viewModel.message
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
    let biometricType = delegate.biometricType
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
      delegate.viewControllerDidTryBiometrics(self)
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

        if strongSelf.viewModel.shouldAnimateMessage {
          strongSelf.messageLabel.alpha = 1
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

  func authenticationSatisfied() {
    delegate.viewControllerDidSuccessfullyAuthenticate(self, completion: self.successHandler)
  }
}

extension PinEntryViewController: KeypadEntryViewDelegate {
  func selected(digit: String) {
    let addDigitResult = digitEntryDisplayViewModel.add(digit: digit)
    resetErrorLabel()
    guard addDigitResult == .complete else { return }
    if delegate.checkMatch(for: digitEntryDisplayViewModel.digits) {
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
        self.authenticationSatisfied()
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
