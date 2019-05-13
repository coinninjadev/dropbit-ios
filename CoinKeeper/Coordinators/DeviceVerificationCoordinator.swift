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
import os.log

protocol DeviceVerificationCoordinatorDelegate: TwilioErrorDelegate {
  var launchStateManager: LaunchStateManagerType { get }
  var networkManager: NetworkManagerType { get }
  var walletManager: WalletManagerType? { get }
  var persistenceManager: PersistenceManagerType { get }
  var alertManager: AlertManagerType { get }

  func coordinator(_ coordinator: DeviceVerificationCoordinator, didVerify phoneNumber: GlobalPhoneNumber, isInitialSetupFlow: Bool)
  func coordinator(_ coordinator: DeviceVerificationCoordinator, didVerify twitterCredentials: TwitterOAuthStorage, isInitialSetupFlow: Bool)
  //func coordinator(_ coordinator: DeviceVerificationCoordinator, didVerify phoneNumber: GlobalPhoneNumber, isInitialSetupFlow: Bool)
  func coordinatorSkippedPhoneVerification(_ coordinator: DeviceVerificationCoordinator)
  func registerAndPersistWallet(in context: NSManagedObjectContext) -> Promise<Void>
}

class DeviceVerificationCoordinator: ChildCoordinatorType {

  weak var navigationController: UINavigationController!
  weak var delegate: ChildCoordinatorDelegate?

  var userSuppliedPhoneNumber: GlobalPhoneNumber?
  let logger = OSLog(subsystem: "com.coinninja.coinkeeper.deviceverificationcoordinator", category: "device_verification_coordinator")
  var isInitialSetupFlow = true

  // MARK: private var
  private var codeEntryFailureCount = 0
  private let maxCodeEntryFailures = 3
  private let minHudDisplayDuration: TimeInterval = 0.5
  private let shouldOrphanRoot: Bool
  private let userIdentityType: UserIdentityType

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
    switch userIdentityType {
    case .phone:
      let viewController = DeviceVerificationViewController.makeFromStoryboard()
      viewController.shouldOrphan = shouldOrphanRoot
      assignCoordinationDelegate(to: viewController)
      navigationController.pushViewController(viewController, animated: true)
    case .twitter:
      guard let delegate = coordinationDelegate else { return }
      let context = delegate.persistenceManager.createBackgroundContext()
      var credentials: TwitterOAuthStorage!
      delegate.networkManager.authorizedTwitterCredentials()
        .get { credentials = $0 }
        .then { return Promise.value(CreateUserBody(twitterCredentials: $0)) }
        .then(in: context) { self.registerAndPersistUser(with: $0, delegate: delegate, in: context) }
        .then { _ -> Promise<UserResponse> in delegate.networkManager.verifyUser(twitterCredentials: credentials) }
        .then { (response: UserResponse) -> Promise<Void> in
          os_log("user response: %@", log: self.logger, type: .debug, response.id)
          return self.checkAndPersistVerificationStatus(from: response, crDelegate: delegate, in: context)
        }
        .get(in: context) { _ in
          do {
            try context.save()
          } catch {
            os_log("failed to save context in %@. error: %@", log: self.logger, type: .error, #function, error.localizedDescription)
          }
        }
        .done { _ in delegate.coordinator(self, didVerify: credentials, isInitialSetupFlow: false) }
        .catch { error in
          os_log("failed to create or verify user in %@. error: %@", log: self.logger, type: .error, #function, error.localizedDescription)
        }
    }
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

  func viewController(_ phoneNumberEntryViewController: DeviceVerificationViewController, didEnterPhoneNumber phoneNumber: GlobalPhoneNumber) {
    // Hold phone number in memory for code verification
    self.userSuppliedPhoneNumber = phoneNumber

    guard let crDelegate = self.coordinationDelegate else { return }

    crDelegate.alertManager.showActivityHUD(withStatus: nil)

    let bgContext = crDelegate.persistenceManager.createBackgroundContext()
    bgContext.perform {
      crDelegate.registerAndPersistWallet(in: bgContext)
        .then(in: bgContext) { _ -> Promise<Void> in
          let body = CreateUserBody(phoneNumber: phoneNumber)
          return self.registerAndPersistUser(with: body, delegate: crDelegate, in: bgContext)
        }
        .done(on: .main) {

          crDelegate.alertManager.hideActivityHUD(withDelay: self.minHudDisplayDuration) {
            // Push code entry view controller
            let codeEntryViewController = DeviceVerificationViewController.makeFromStoryboard()
            self.assignCoordinationDelegate(to: codeEntryViewController)
            codeEntryViewController.entryMode = .codeVerification(phoneNumber)
            self.navigationController.pushViewController(codeEntryViewController, animated: true)
            self.codeEntryFailureCount = 0
          }

        }
        .catch(on: .main, policy: .allErrors) { error in
          os_log("User registration failed: %@", log: self.logger, type: .error, error.localizedDescription)
          self.handleUserRegistrationFailure(withError: error, phoneNumber: phoneNumber, delegate: crDelegate)
        }
        .finally(in: bgContext) {
          do {
            try bgContext.save()
          } catch {
            os_log("User registration failed: %@", log: self.logger, type: .error, error.localizedDescription)
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
      let body = CreateUserBody(phoneNumber: phoneNumber)
      crDelegate.persistenceManager.defaultHeaders(in: bgContext)
        .then { crDelegate.networkManager.resendVerification(headers: $0, body: body) }
        .done { [weak self] _ in
          guard let strongSelf = self, let coordinationDelegate = strongSelf.coordinationDelegate else { return }
          coordinationDelegate.alertManager.showSuccess(message: "You will receive a verification code SMS shortly",
                                                        forDuration: 2.0)
          os_log("Successfully requested code resend", log: strongSelf.logger, type: .info)
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
    os_log("Failed to request code: %@", log: self.logger, type: .error, error.localizedDescription)
    let message = errorMessageFactory.messageForResendCodeFailure(error: error)
    self.showVerificationErrorAlert(.custom(message), delegate: coordinationDelegate)
  }

  fileprivate func registerAndPersistUser(with body: CreateUserBody,
                                          delegate: DeviceVerificationCoordinatorDelegate,
                                          in context: NSManagedObjectContext) -> Promise<Void> {

    var maybeWalletId: String?
    context.performAndWait {
      maybeWalletId = delegate.persistenceManager.walletId(in: context)
    }
    guard let walletId = maybeWalletId else {
      return Promise { $0.reject(CKPersistenceError.missingValue(key: "wallet ID")) }
    }

    return delegate.networkManager.createUser(walletId: walletId, body: body)
      .recover { (error: Error) -> Promise<UserResponse> in
        return self.handleCreateUserError(error, walletId: walletId, delegate: delegate, in: context)
      }
      .get(in: context) { delegate.persistenceManager.persistUserId($0.id, in: context) }.asVoid()
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
        delegate.persistenceManager.persistUserId(userId, in: context)

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
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "device_verification_coordinator")
    let bgContext = crDelegate.persistenceManager.createBackgroundContext()
    bgContext.perform {
      crDelegate.networkManager.verifyUser(phoneNumber: phoneNumber, code: code)
        .then(in: bgContext) { self.checkAndPersistVerificationStatus(from: $0, crDelegate: crDelegate, in: bgContext) }
        .get(in: bgContext) { _ in
          do {
            try bgContext.save()
          } catch {
            os_log("Failed to save context. %@", log: logger, type: .error, error.localizedDescription)
          }
        }
        .done(on: .main) { _ in

          crDelegate.persistenceManager.keychainManager.store(anyValue: phoneNumber.countryCode, key: .countryCode)
          crDelegate.persistenceManager.keychainManager.store(anyValue: phoneNumber.nationalNumber, key: .phoneNumber)

          // Tell delegate to continue app flow
          self.codeWasVerified(phoneNumber: phoneNumber)
          self.userSuppliedPhoneNumber = nil // userSuppliedPhoneNumber should remain set until verification succeeds
          completion(true)
        }
        .catch(on: .main) { [weak self] error in
          os_log("Failed entering code to verify user. %@", log: logger, type: .error, error.localizedDescription)
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

    return crDelegate.persistenceManager.persistVerificationStatus(from: response, in: context).asVoid()
  }

  func viewControllerDidSkipPhoneVerification(_ viewController: DeviceVerificationViewController) {
    guard let crDelegate = coordinationDelegate else { return }

    crDelegate.alertManager.showActivityHUD(withStatus: nil)
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "device_verification_coordinator")
    // Register wallet before notifying delegate of skip
    let bgContext = crDelegate.persistenceManager.createBackgroundContext()
    bgContext.perform {
      crDelegate.registerAndPersistWallet(in: bgContext)
        .done {

          crDelegate.alertManager.hideActivityHUD(withDelay: self.minHudDisplayDuration) {
            crDelegate.coordinatorSkippedPhoneVerification(self)
          }
        }
        .catch { error in
          let message = "Failed to register wallet: \(error)"
          os_log("Failed to register wallet: %@", log: logger, type: .error, error.localizedDescription)
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
    coordinationDelegate?.coordinator(self, didVerify: phoneNumber, isInitialSetupFlow: self.isInitialSetupFlow)
  }

  private func codeFailureCountExceeded() {
    navigationController.popViewController(animated: true)
    navigationController.topViewController.flatMap { $0 as? DeviceVerificationViewController }?.entryMode = .codeFailureCountExceeded
  }
}
