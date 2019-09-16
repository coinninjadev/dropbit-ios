//
//  AppCoordinator+RemoteNotifications.swift
//  DropBit
//
//  Created by Ben Winters on 5/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator {

  func registerForRemoteNotifications(with deviceToken: Data) {
    let token = deviceToken.hexString
    persistenceManager.brokers.device.setDeviceToken(string: token)
    notificationManager.performRegistrationIfNeeded(forPushToken: token)
  }

  func requestPushNotificationDialogueIfNeeded() {
    switch permissionManager.permissionStatus(for: .notification) {
    case .authorized:
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
      }
    case .disabled, .denied:
      notificationManager.removeSubscriptions()
    case .notDetermined:
      showPushNotificationActionableAlert()
    }
  }

  func showPushNotificationActionableAlert() {
    guard uiTestArguments.isEmpty else { return }
    let requestConfiguration = AlertActionConfiguration(title: "GOT IT", style: .default, action: { [weak self] in
      self?.permissionManager.requestPermission(for: .notification) { status in
        switch status {
        case .authorized:
          DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
          }
        default:
          break
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
          self?.presentDropBitMeViewController(verifiedFirstTime: true)
        }
      }
    })

    let title = "Push notifications are an important part of the DropBit experience." +
    " Without them you will not be notified to complete transactions which will cause them to expire."

    let description = "Please allow us to send you push notifications on the following prompt."
    let alert = alertManager.detailedAlert(withTitle: title, description: description, image: #imageLiteral(resourceName: "dropBitBadgeIcon"), style: .warning, action: requestConfiguration)

    navigationController.topViewController()?.present(alert, animated: true)
  }

}
