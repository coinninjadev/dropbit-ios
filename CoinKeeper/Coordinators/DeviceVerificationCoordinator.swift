//
//  DeviceVerificationCoordinator.swift
//  CoinKeeper
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

  func coordinator(_ coordinator: DeviceVerificationCoordinator, didVerify type: UserIdentityType, isInitialSetupFlow: Bool)
  func coordinatorSkippedPhoneVerification(_ coordinator: DeviceVerificationCoordinator)
  func registerAndPersistWallet(in context: NSManagedObjectContext) -> Promise<Void>
}

class DeviceVerificationCoordinator: ChildCoordinatorType {

  weak var navigationController: UINavigationController!
  weak var delegate: ChildCoordinatorDelegate?

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

  private var coordinationDelegate: DeviceVerificationCoordinatorDelegate? {
    return delegate as? DeviceVerificationCoordinatorDelegate
  }

  required init(_ navigationController: UINavigationController, userIdentityType: UserIdentityType, shouldOrphanRoot: Bool = true) {
    self.navigationController = navigationController
    self.userSuppliedPhoneNumber = nil
    self.userIdentityType = userIdentityType
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
    guard let delegate = coordinationDelegate, let presentingViewController = navigationController.topViewController() else { return }
    let context = delegate.persistenceManager.createBackgroundContext()
    context.perform {
      self.registerAndPersistWalletIfNecessary(delegate: delegate, in: context)
        .then(in: context) { delegate.twitterAccessManager.authorizedTwitterCredentials(presentingViewController: presentingViewController) }
        .then(in: context) { self.addTwitterUserIdentity(credentials: $0, delegate: delegate, in: context) }
        .then(in: context) { body, creds -> Promise<UserResponse> in
          return delegate.networkManager.verifyUser(body: body, credentials: creds)
        }
        .then(in: context) { (response: UserResponse) -> Promise<Void> in
          log.debug("user response: \(response.id)")
          return self.checkAndPersistVerificationStatus(from: response, crDelegate: delegate, in: context)
        }
        .then(in: context) { _ in delegate.twitterAccessManager.getCurrentTwitterUser(in: context) }
        .get(in: context) { _ in
          do {
            try context.save()
          } catch {
            log.contextSaveError(error)
          }
        }
        .done { _ in delegate.coordinator(self, didVerify: .twitter, isInitialSetupFlow: self.isInitialSetupFlow) }
        .catch { error in
          self.coordinationDelegate?.alertManager.showError(message: error.localizedDescription, forDuration: 3.0)
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
    in context: NSManagedObjectContext) -> Promise<(VerifyUserBody, TwitterOAuthStorage)> {

    let userIdentityBody = UserIdentityBody(twitterCredentials: credentials)
    return self.registerUser(with: userIdentityBody, delegate: delegate, shouldPersistUserId: true, in: context)
      .then { _ in return Promise.value((VerifyUserBody(twitterCredentials: credentials), credentials)) }
  }
}

extension DeviceVerificationCoordinator: DeviceVerificationViewControllerDelegate {

  func viewControllerShouldShowSkipButton() -> Bool {
    guard let skippedVerification =
      coordinationDelegate?.persistenceManager.keychainManager.retrieveValue(for: .skippedVerification) as? NSNumber else {
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

    guard let crDelegate = self.coordinationDelegate else { return }

    crDelegate.alertManager.showActivityHUD(withStatus: nil)

    let bgContext = crDelegate.persistenceManager.createBackgroundContext()
    bgContext.perform {
      crDelegate.registerAndPersistWallet(in: bgContext)
        .then(in: bgContext) { _ -> Promise<UserIdentifiable> in
          let body = UserIdentityBody(phoneNumber: phoneNumber)
          return self.registerUser(with: body, delegate: crDelegate, shouldPersistUserId: false, in: bgContext)
        }
        .done(on: .main) { userIdentifiable in

          crDelegate.alertManager.hideActivityHUD(withDelay: self.minHudDisplayDuration) {
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
          self.handleUserRegistrationFailure(withError: error, phoneNumber: phoneNumber, delegate: crDelegate)
        }
        .finally(in: bgContext) {
          do {
            try bgContext.save()
          } catch {
            log.error(error, message: "user registration failed")
          }
      }
    }
  }

  func viewControllerDidRequestResendCode(_ viewController: DeviceVerificationViewController) {
    guard let crDelegate = self.coordinationDelegate else { return }
    guard let phoneNumber = self.userSuppliedPhoneNumber else {
      assertionFailure("Phone number not set, cannot request resend code")
      return
    }

    let bgContext = crDelegate.persistenceManager.createBackgroundContext()
    bgContext.perform {
      let body = UserIdentityBody(phoneNumber: phoneNumber)
      crDelegate.persistenceManager.defaultHeaders(in: bgContext)
        .then { crDelegate.networkManager.resendVerification(headers: $0, body: body) }
        .done { [weak self] _ in
          guard let strongSelf = self, let coordinationDelegate = strongSelf.coordinationDelegate else { return }
          coordinationDelegate.alertManager.showSuccess(message: "You will receive a verification code SMS shortly",
                                                        forDuration: 2.0)
          log.info("Successfully requested code resend")
        }
        .catch { [weak self] error in
          self?.handleResendError(error)
          if let providerError = error as? UserProviderError, case .twilioError = providerError {
            crDelegate.didReceiveTwilioError(for: body.identity, route: .resendVerification)
          }
      }
    }
  }

  private func handleResendError(_ error: Error) {
    guard let coordinationDelegate = self.coordinationDelegate else { return }
    log.error(error, message: "failed to request code")
    let message = errorMessageFactory.messageForResendCodeFailure(error: error)
    self.showVerificationErrorAlert(.custom(message), delegate: coordinationDelegate)
  }

  fileprivate func registerAndPersistWalletIfNecessary(delegate: DeviceVerificationCoordinatorDelegate,
                                                       in context: NSManagedObjectContext) -> Promise<Void> {
    if delegate.persistenceManager.brokers.wallet.walletId(in: context) == nil {
      return delegate.registerAndPersistWallet(in: context)
    } else {
      return .value(()) //registration not needed
    }
  }

  fileprivate func registerUser(with body: UserIdentityBody,
                                delegate: DeviceVerificationCoordinatorDelegate,
                                shouldPersistUserId: Bool,
                                in context: NSManagedObjectContext) -> Promise<UserIdentifiable> {

    var maybeWalletId: String?
    context.performAndWait {
      maybeWalletId = delegate.persistenceManager.brokers.wallet.walletId(in: context)
    }
    guard let walletId = maybeWalletId else {
      return Promise { $0.reject(CKPersistenceError.missingValue(key: "wallet ID")) }
    }

    return self.createUserOrIdentity(walletId: walletId, body: body, delegate: delegate, in: context)
      .recover { (error: Error) -> Promise<UserIdentifiable> in
        return self.handleCreateUserError(error, walletId: walletId, delegate: delegate, in: context)
          .map { $0 as UserIdentifiable }
      }
      .get(in: context) { identifiable in
        if shouldPersistUserId {
          delegate.persistenceManager.brokers.user.persistUserId(identifiable.id, in: context)
        }
      }
  }

  private func createUserOrIdentity(
    walletId: String,
    body: UserIdentityBody,
    delegate: DeviceVerificationCoordinatorDelegate,
    in context: NSManagedObjectContext
    ) -> Promise<UserIdentifiable> {
    let verifiedIdentities = delegate.persistenceManager.brokers.user.verifiedIdentities(in: context)
    if verifiedIdentities.count == 1 {
      return delegate.networkManager.addIdentity(body: body).map { $0 as UserIdentifiable }
    } else {
      return delegate.networkManager.createUser(walletId: walletId, body: body).map { $0 as UserIdentifiable }
    }
  }

  /// If createUser results in statusCode 200, that function rejects with .userAlreadyExists and
  /// we recover by calling resendVerification(). In the case of a Twilio error, we notify the delegate
  /// for analytics and continue as normal. In both cases we eventually return a UserResponse so that
  /// we can persist the userId returned by the server.
  private func handleCreateUserError(_ error: Error,
                                     walletId: String,
                                     delegate: DeviceVerificationCoordinatorDelegate,
                                     in context: NSManagedObjectContext) -> Promise<UserResponse> {
    if let providerError = error as? UserProviderError {
      switch providerError {
      case .userAlreadyExists(let userId, let body):
        //ignore walletId available in the error in case it is different from the walletId we provided
        let resendHeaders = DefaultRequestHeaders(walletId: walletId, userId: userId)

        return delegate.networkManager.resendVerification(headers: resendHeaders, body: body)
          .recover { (error: Error) -> Promise<UserResponse> in
            if let providerError = error as? UserProviderError,
              case let .twilioError(userResponse, _) = providerError {
              delegate.didReceiveTwilioError(for: body.identity, route: .resendVerification)
              return Promise.value(userResponse)
            } else {
              throw error
            }
        }
      case .twilioError(let userResponse, let body):
        delegate.didReceiveTwilioError(for: body.identity, route: .createUser)
        return Promise.value(userResponse)
      default:
        return Promise(error: error)
      }
    } else {
      return Promise(error: error)
    }
  }

  func viewController(_ codeEntryViewController: DeviceVerificationViewController, didEnterCode code: String, completion: @escaping (Bool) -> Void) {
    guard let crDelegate = self.coordinationDelegate else { return }
    guard let phoneNumber = self.userSuppliedPhoneNumber else { fatalError("Programmer error: call didEnterPhoneNumber: first") }
    let bgContext = crDelegate.persistenceManager.createBackgroundContext()
    bgContext.perform {
      let body = VerifyUserBody(phoneNumber: phoneNumber, code: code)
      crDelegate.networkManager.verifyUser(body: body)
        .then(in: bgContext) { self.checkAndPersistVerificationStatus(from: $0, crDelegate: crDelegate, in: bgContext) }
        .get(in: bgContext) { _ in
          do {
            try bgContext.save()
          } catch {
            log.contextSaveError(error)
          }
        }
        .then { crDelegate.persistenceManager.keychainManager.store(anyValue: phoneNumber.countryCode, key: .countryCode) }
        .then { crDelegate.persistenceManager.keychainManager.store(anyValue: phoneNumber.nationalNumber, key: .phoneNumber) }
        .done(on: .main) { _ in

          // Tell delegate to continue app flow
          self.codeWasVerified(phoneNumber: phoneNumber)
          self.userSuppliedPhoneNumber = nil // userSuppliedPhoneNumber should remain set until verification succeeds
          completion(true)
        }
        .catch(on: .main) { [weak self] error in
          log.error(error, message: "Failed entering code to verify user")
          self?.handleCodeEntryFailure(withError: error, delegate: crDelegate)
          completion(false)
      }
    }
  }

  private func handleUserRegistrationFailure(withError error: Error,
                                             phoneNumber: GlobalPhoneNumber,
                                             delegate: DeviceVerificationCoordinatorDelegate) {
    guard let networkError = CKNetworkError(for: error) else {
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
    guard let networkError = CKNetworkError(for: error) else {
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

  private func checkAndPersistVerificationStatus(from response: UserResponse,
                                                 crDelegate: DeviceVerificationCoordinatorDelegate,
                                                 in context: NSManagedObjectContext) -> Promise<Void> {
    guard let statusCase = UserVerificationStatus(rawValue: response.status) else {
      return Promise { $0.reject(CKNetworkError.responseMissingValue(keyPath: UserResponseKey.status.path)) }
    }
    guard statusCase == .verified else {
      return Promise { $0.reject(UserProviderError.unexpectedStatus(statusCase)) }
    }

    return crDelegate.persistenceManager.brokers.user.persistVerificationStatus(from: response, in: context).asVoid()
  }

  func viewControllerDidSkipPhoneVerification(_ viewController: DeviceVerificationViewController) {
    guard let crDelegate = coordinationDelegate else { return }

    crDelegate.alertManager.showActivityHUD(withStatus: nil)
    // Register wallet before notifying delegate of skip
    let bgContext = crDelegate.persistenceManager.createBackgroundContext()
    bgContext.perform {
      crDelegate.registerAndPersistWallet(in: bgContext)
        .done(in: bgContext) {
          try bgContext.save()

          DispatchQueue.main.async {
            crDelegate.alertManager.hideActivityHUD(withDelay: self.minHudDisplayDuration) {
              crDelegate.coordinatorSkippedPhoneVerification(self)
            }
          }
        }
        .catch { error in
          log.error(error, message: "Failed to register wallet")
          let message = "Failed to register wallet: \(error)"
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
    coordinationDelegate?.coordinator(self, didVerify: .phone, isInitialSetupFlow: self.isInitialSetupFlow)
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
