//
//  AppDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 1/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import OAuthSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var coordinator: AppCoordinator?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    if coordinator == nil {
      setupCoordinator()
    }

    return true
  }

  func applicationWillResignActive(_ application: UIApplication) {
    coordinator?.appWillResignActiveState()
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    coordinator?.appEnteredActiveState()
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    coordinator?.appBecameActive()
  }

  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    coordinator?.registerForRemoteNotifications(with: deviceToken)
  }

  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("failed to register for remote notifications")
  }

  func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    requestBackgroundSync(completion: completionHandler)
  }

  func application(_ application: UIApplication,
                   didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                   fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    requestBackgroundSync(completion: completionHandler)
  }

  private func requestBackgroundSync(completion completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    if coordinator == nil {
      setupCoordinator()
    }
    DispatchQueue.main.async { [weak self] in
      guard UIApplication.shared.applicationState != .active else { completionHandler(.noData); return }
      DispatchQueue.global(qos: .background).async {
        self?.coordinator?.serialQueueManager.enqueueWalletSyncIfAppropriate(type: .standard,
                                                                             policy: .always,
                                                                             completion: nil,
                                                                             fetchResult: completionHandler
        )
      }
    }
  }

  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if coordinator == nil {
      setupCoordinator()
    }

    if url.scheme == "dropbit" {
      OAuthSwift.handle(url: url)
      return true
    }

    guard let bitcoinURL = BitcoinURL(string: url.absoluteString) else {
      return false
    }

    coordinator?.bitcoinURLToOpen = bitcoinURL

    return true
  }

  // MARK: private
  private func setupCoordinator() {
    window = UIWindow()
    let viewController = StartViewController.makeFromStoryboard()
    let navigationController = CNNavigationController(rootViewController: viewController)
    window?.rootViewController = navigationController
    window?.makeKeyAndVisible()

    let uiTestArguments = ProcessInfo.processInfo.arguments.compactMap { UITestArgument(string: $0) }
    coordinator = AppCoordinator(navigationController: navigationController, uiTestArguments: uiTestArguments)
    coordinator?.start()
  }
}
