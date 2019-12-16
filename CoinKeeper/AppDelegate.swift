//
//  AppDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 1/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import OAuthSwift
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  var _coordinator: AppCoordinator?
  var coordinator: AppCoordinator {
    if let existing = _coordinator {
      return existing
    } else {
      let new = createCoordinator()
      _coordinator = new
      _coordinator?.start()
      return new
    }
  }

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    log.systemEvent()
    _ = coordinator //trigger setup of coordinator
    return true
  }

  func applicationWillResignActive(_ application: UIApplication) {
    log.systemEvent(synchronize: true)
    coordinator.appWillResignActiveState()
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    log.systemEvent()
    coordinator.appEnteredActiveState()
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    log.systemEvent()
    coordinator.appBecameActive()
  }

  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    log.systemEvent()
    coordinator.registerForRemoteNotifications(with: deviceToken)
  }

  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    log.error(error, message: "failed to register for remote notifications")
  }

  func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    log.systemEvent()
    requestBackgroundSync(completion: completionHandler)
  }

  func application(_ application: UIApplication,
                   didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                   fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    log.systemEvent()
    requestBackgroundSync(completion: completionHandler)
  }

  private func requestBackgroundSync(completion completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    DispatchQueue.main.async { [weak self] in
      guard UIApplication.shared.applicationState != .active else { completionHandler(.noData); return }
      DispatchQueue.global(qos: .background).async {
        self?.coordinator.serialQueueManager.enqueueWalletSyncIfAppropriate(type: .standard,
                                                                             policy: .always,
                                                                             completion: nil,
                                                                             fetchResult: completionHandler
        )
      }
    }
  }

  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    log.systemEvent()

    if url.scheme == "dropbit" {
      if let wyreURL = WyreURLParser(url: url) {
        coordinator.purchasedBitcoinComponents = wyreURL
      } else {
        OAuthSwift.handle(url: url)
      }
      return true

    } else if let bitcoinURL = BitcoinURL(string: url.absoluteString) {
      coordinator.bitcoinURLToOpen = bitcoinURL
      return true

    } else if DynamicLinks.dynamicLinks().shouldHandleDynamicLink(fromCustomSchemeURL: url) {
      let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url)
      return coordinator.handleDynamicLink(dynamicLink)

    } else {
      return false
    }
  }

  // MARK: private
  private func createCoordinator() -> AppCoordinator {
    log.event("Will set up coordinator")
    window = UIWindow()
    let viewController = StartViewController.newInstance(delegate: nil)
    let navigationController = CNNavigationController(rootViewController: viewController)
    window?.rootViewController = navigationController
    window?.makeKeyAndVisible()

    let uiTestArguments = ProcessInfo.processInfo.arguments.compactMap { UITestArgument(string: $0) }
    let coord = AppCoordinator(navigationController: navigationController, uiTestArguments: uiTestArguments)
    viewController.delegate = coord
    return coord
  }
}
