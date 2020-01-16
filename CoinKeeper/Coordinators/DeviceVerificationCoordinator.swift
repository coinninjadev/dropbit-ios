//
//  DeviceVerificationCoordinator.swift
//  DropBit
//
//  Created by Bill Feth on 4/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import PromiseKit
import UIKit

protocol DeviceVerificationCoordinatorDelegate: TwilioErrorDelegate {
  var launchStateManager: LaunchStateManagerType { get }
  var networkManager: NetworkManagerType { get }
  var walletManager: WalletManagerType? { get }
  var persistenceManager: PersistenceManagerType { get }
  var alertManager: AlertManagerType { get }
  var twitterAccessManager: TwitterAccessManagerType { get }
  var userIdentifiableManager: UserIdentifiableManagerType { get }

  func coordinator(_ coordinator: DeviceVerificationCoordinator, didVerify type: UserIdentityType, isInitialSetupFlow: Bool)
  func coordinatorSkippedPhoneVerification(_ coordinator: DeviceVerificationCoordinator)
  func registerAndPersistWallet(in context: NSManagedObjectContext) -> Promise<Void>
}

class DeviceVerificationCoordinator: ChildCoordinatorType {

  weak var navigationController: UINavigationController!
  weak var childCoordinatorDelegate: ChildCoordinatorDelegate!

  var userSuppliedPhoneNumber: GlobalPhoneNumber?

  var selectedSetupFlow: SetupFlow?
  var isInitialSetupFlow: Bool {
    return selectedSetupFlow != nil
  }

  // MARK: private var
  private var codeEntryFailureCount = 0
  private let maxCodeEntryFailures = 3
  private let minHudDisplayDuration: TimeInterval = 0.5
  private let shouldOrphanRoot: Bool
  private var userIdentityType: UserIdentityType

  private let errorMessageFactory = DeviceVerificationErrorMessageFactory()

  private(set) weak var delegate: DeviceVerificationCoordinatorDelegate!

  required init(_ navigationController: UINavigationController,
                delegate: DeviceVerificationCoordinatorDelegate,
                coordinationDelegate: ChildCoordinatorDelegate,
                userIdentityType: UserIdentityType,
                setupFlow: SetupFlow?,
                shouldOrphanRoot: Bool = true) {
    self.navigationController = navigationController
    self.delegate = delegate
    self.userSuppliedPhoneNumber = nil
    self.userIdentityType = userIdentityType
    self.selectedSetupFlow = setupFlow
    self.shouldOrphanRoot = shouldOrphanRoot
  }

  func start() {
    continueDeviceVerificationFlow()
  }

  fileprivate func continueDeviceVerificationFlow() {
    if let selectedFlow = selectedSetupFlow, case let .claimInvite(method) = selectedFlow {
      if let selectedMethod = method {
        self.startVerification(forType: selectedMethod)
      } else {
        // flow is .claimInvite, but method not yet selected
        self.startClaimInvite()
      }
    } else {
      self.startVerification(forType: userIdentityType)
    }
  }

  private func startVerification(forType type: UserIdentityType) {
    switch type {
    case .phone:
      startPhoneVerification()
    case .twitter:
      startTwitterVerification()
    }
  }

  private func startPhoneVerification() {
    let viewController = DeviceVerificationViewController.newInstance(delegate: self,
                                                                      entryMode: .phoneNumberEntry,
                                                                      setupFlow: selectedSetupFlow,
                                                                      shouldOrphan: shouldOrphanRoot)
    navigationController.pushViewController(viewController, animated: true)
  }

  private func startTwitterVerification() {
    guard let delegate = self.delegate, let presentingViewController = navigationController.topViewController() else { return }
    let context = delegate.persistenceManager.createBackgroundContext()
    context.perform {
      self.registerAndPersistWalletIfNecessary(delegate: delegate, in: context)
        .then(in: context) { delegate.twitterAccessManager.authorizeAndStoreTwitterCredentials(
          presentingViewController: presentingViewController,
          in: context) }
        .done { _ in delegate.coordinator(self, didVerify: .twitter, isInitialSetupFlow: self.isInitialSetupFlow) }
        .catch { error in
          delegate.alertManager.showErrorHUD(error, forDuration: 3.0)
          log.error(error, message: "failed to create or verify user")
      }
    }
  }

  private func startClaimInvite() {
    let vc = ClaimInviteMethodViewController.newInstance(delegate: self)
    navigationController.pushViewController(vc, animated: true)
  }

  func addTwitterUserIdentity(
    credentials: TwitterOAuthStorage,
    delegate: DeviceVerificationCoordinatorDelegate,
    in context: NSManagedObjectContext) -> Promise<UserIdentifiable> {
    let userIdentityBody = UserIdentityBody(twitterCredentials: credentials)
    return delegate.userIdentifiableManager.registerUser(with: userIdentityBody,
                                                         in: context)
  }
}

extension DeviceVerificationCoordinator: DeviceVerificationViewControllerDelegate {

  func viewControllerShouldShowSkipButton() -> Bool {
    guard let skippedVerification =
      delegate.persistenceManager.keychainManager.retrieveValue(for: .skippedVerification) as? NSNumber else {
        return true
    }

    if skippedVerification == NSNumber(value: true) {
      return false
    } else {
      return true
    }
  }

  func viewControllerDidSelectVerifyTwitter(_ viewController: UIViewController) {
    self.userIdentityType = .twitter
    continueDeviceVerificationFlow()
  }

  func viewController(_ phoneNumberEntryViewController: DeviceVerificationViewController, didEnterPhoneNumber phoneNumber: GlobalPhoneNumber) {
    // Hold phone number in memory for code verification
    self.userSuppliedPhoneNumber = phoneNumber

    guard let delegate = self.delegate else { return }

    delegate.alertManager.showActivityHUD(withStatus: nil)

    let bgContext = delegate.persistenceManager.createBackgroundContext()
    bgContext.perform {
      delegate.registerAndPersistWallet(in: bgContext)
        .then(in: bgContext) { _ -> Promise<UserIdentifiable> in
          let body = UserIdentityBody(phoneNumber: phoneNumber)
          return delegate.userIdentifiableManager.registerUser(with: body, in: bgContext)
        }
        .get(in: bgContext) { _ in
          do {
            try bgContext.saveRecursively()
          } catch {
            log.contextSaveError(error)
            throw error
          }
        }
        .done(on: .main) { userIdentifiable in

          delegate.alertManager.hideActivityHUD(withDelay: self.minHudDisplayDuration) {
            // Push code entry view controller
            let codeEntryVC = DeviceVerificationViewController.newInstance(delegate: self,
                                                                           entryMode: .codeVerification(phoneNumber),
                                                                           setupFlow: nil,
                                                                           userIdToVerify: userIdentifiable.id)
            self.navigationController.pushViewController(codeEntryVC, animated: true)
            self.codeEntryFailureCount = 0
          }

        }
        .catch(on: .main, policy: .allErrors) { error in
          log.error(error, message: "user registration failed")
          self.handleUserRegistrationFailure(withError: error, phoneNumber: phoneNumber, delegate: delegate)
        }
    }
  }

  func viewControllerDidRequestResendCode(_ viewController: DeviceVerificationViewController, temporaryUserId: String) {
    guard let delegate = self.delegate else { return }
    guard let phoneNumber = self.userSuppliedPhoneNumber else {
      assertionFailure("Phone number not set, cannot request resend code")
      return
    }

    let body = UserIdentityBody(phoneNumber: phoneNumber)
    let context = delegate.persistenceManager.viewContext
    delegate.persistenceManager.defaultHeaders(temporaryUserId: temporaryUserId, in: context)
      .then { delegate.networkManager.resendVerification(headers: $0, body: body) }
      .done { _ in
        delegate.alertManager.showSuccess(message: "You will receive a verification code SMS shortly",
                                          forDuration: 2.0)
        log.info("Successfully requested code resend")
      }
      .catch { [weak self] error in
        self?.handleResendError(error)
        if let providerError = error as? DBTError.UserRequest, case .twilioError = providerError {
          delegate.didReceiveTwilioError(for: body.identity, route: .resendVerification)
        }
      }
  }

  private func handleResendError(_ error: Error) {
    log.error(error, message: "failed to request code")
    let message = errorMessageFactory.messageForResendCodeFailure(error: error)
    self.showVerificationErrorAlert(.custom(message), delegate: self.delegate)
  }

  fileprivate func registerAndPersistWalletIfNecessary(delegate: DeviceVerificationCoordinatorDelegate,
                                                       in context: NSManagedObjectContext) -> Promise<Void> {
    if delegate.persistenceManager.brokers.wallet.walletId(in: context) == nil {
      return delegate.registerAndPersistWallet(in: context).asVoid()
    } else {
      return .value(()) //registration not needed
    }
  }

  func viewController(_ codeEntryViewController: DeviceVerificationViewController,
                      didEnterCode code: String,
                      forUserId userId: String,
                      completion: @escaping (Bool) -> Void) {
    guard let delegate = self.delegate else { return }
    guard let phoneNumber = self.userSuppliedPhoneNumber else { fatalError("Programmer error: call didEnterPhoneNumber: first") }
    let bgContext = delegate.persistenceManager.createBackgroundContext()
    bgContext.perform {
      let maybeReferrer = delegate.persistenceManager.brokers.user.referredBy
      let body = VerifyUserBody(phoneNumber: phoneNumber, code: code, referrer: maybeReferrer)
      delegate.networkManager.verifyUser(id: userId, body: body)
        .get(in: bgContext) { response in delegate.persistenceManager.brokers.user.persistUserId(response.id, in: bgContext) }
        .then(in: bgContext) { delegate.userIdentifiableManager.checkAndPersistVerificationStatus(from: $0, in: bgContext) }
        .then { delegate.networkManager.getOrCreateLightningAccount() }
        .get(in: bgContext) { lnAccountResponse in
          delegate.persistenceManager.brokers.lightning.persistAccountResponse(lnAccountResponse, in: bgContext)
          do {
            try bgContext.saveRecursively()
          } catch {
            log.contextSaveError(error)
          }
        }
        .then { _ in delegate.persistenceManager.keychainManager.store(anyValue: phoneNumber.countryCode, key: .countryCode) }
        .then { delegate.persistenceManager.keychainManager.store(anyValue: phoneNumber.nationalNumber, key: .phoneNumber) }
        .done(on: .main) {

          // Tell delegate to continue app flow
          self.codeWasVerified(phoneNumber: phoneNumber)
          self.userSuppliedPhoneNumber = nil // userSuppliedPhoneNumber should remain set until verification succeeds
          completion(true)
        }
        .catch(on: .main) { [weak self] error in
          log.error(error, message: "Failed entering code to verify user")
          self?.handleCodeEntryFailure(withError: error, delegate: delegate)
          completion(false)
      }
    }
  }

  private func handleUserRegistrationFailure(withError error: Error,
                                             phoneNumber: GlobalPhoneNumber,
                                             delegate: DeviceVerificationCoordinatorDelegate) {
    guard let networkError = DBTError.Network(for: error) else {
      self.showVerificationErrorAlert(.general, delegate: delegate)
      return
    }

    switch networkError {
    case .countryCodeDisabled:
      let message = errorMessageFactory.messageForCountryCodeDisabled(for: phoneNumber)
      self.showVerificationErrorAlert(.custom(message), delegate: delegate)

    case .twilioError:
      self.showVerificationErrorAlert(.custom(errorMessageFactory.twilio), delegate: delegate)

    default:
      self.showVerificationErrorAlert(.general, delegate: delegate)
    }
  }

  private func handleCodeEntryFailure(withError error: Error, delegate: DeviceVerificationCoordinatorDelegate) {
    guard let networkError = DBTError.Network(for: error) else {
      self.showVerificationErrorAlert(.general, delegate: delegate)
      return
    }

    switch networkError {
    case .badResponse:
      self.updateStateForCodeEntryFailure() //shows red error text instead of alert

    case .serverConflict:
      let errorMessage = errorMessageFactory.verificationCodeExpired
      self.showVerificationErrorAlert(.custom(errorMessage), delegate: delegate)

    default:
      self.showVerificationErrorAlert(.general, delegate: delegate)
    }
  }

  private enum ErrorAlertMessageType {
    case general, custom(String)
  }

  private func showVerificationErrorAlert(_ messageType: ErrorAlertMessageType, delegate: DeviceVerificationCoordinatorDelegate) {
    let message: String
    switch messageType {
    case .general:          message = DeviceVerificationErrorMessageFactory.defaultFailureMessage
    case .custom(let msg):  message = msg
    }

    delegate.alertManager.hideActivityHUD(withDelay: minHudDisplayDuration) {
      let alert = delegate.alertManager.defaultAlert(withTitle: "Error", description: message)
      self.navigationController.present(alert, animated: true, completion: nil)
    }
  }

  func viewControllerDidSkipPhoneVerification(_ viewController: DeviceVerificationViewController) {
    guard let delegate = self.delegate else { return }

    delegate.alertManager.showActivityHUD(withStatus: nil)
    // Register wallet before notifying delegate of skip
    let bgContext = delegate.persistenceManager.createBackgroundContext()
    bgContext.perform {
      delegate.registerAndPersistWallet(in: bgContext)
        .done(in: bgContext) { _ in // ignore param, not needed for new wallets
          try bgContext.saveRecursively()

          DispatchQueue.main.async {
            delegate.alertManager.hideActivityHUD(withDelay: self.minHudDisplayDuration) {
              delegate.coordinatorSkippedPhoneVerification(self)
            }
          }
        }
        .catch { error in
          log.error(error, message: "Failed to register wallet")
          let wrapped = DBTError.cast(error)
          let message = "Failed to register wallet: \(wrapped.displayMessage)"
          DispatchQueue.main.async {
            viewController.updateErrorLabel(with: message)
          }
      }
    }
  }

  private func updateStateForCodeEntryFailure() {
    codeEntryFailureCount += 1
    guard codeEntryFailureCount < maxCodeEntryFailures else {
      codeFailureCountExceeded()
      return
    }
    navigationController.topViewController.flatMap { $0 as? DeviceVerificationViewController }?.entryMode = .codeVerificationFailed
  }

  private func codeWasVerified(phoneNumber: GlobalPhoneNumber) {
    delegate.coordinator(self, didVerify: .phone, isInitialSetupFlow: self.isInitialSetupFlow)
  }

  private func codeFailureCountExceeded() {
    navigationController.popViewController(animated: true)
    navigationController.topViewController.flatMap { $0 as? DeviceVerificationViewController }?.entryMode = .codeFailureCountExceeded
  }
}

extension DeviceVerificationCoordinator: ClaimInviteMethodViewControllerDelegate {

  func viewControllerDidSelectClaimInvite(using method: UserIdentityType, viewController: UIViewController) {
    self.selectedSetupFlow = .claimInvite(method: method)
    self.continueDeviceVerificationFlow()
  }

}
