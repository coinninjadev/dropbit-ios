//
//  NotificationManager.swift
//  CoinKeeper
//
//  Created by BJ Miller on 7/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications
import os.log
import CoreData
import PromiseKit

struct NotificationDescription {
  let identifier: String
  let title: String
  let body: String

  init(identifier: String = UUID().uuidString, title: String, body: String) {
    self.identifier = identifier
    self.title = title
    self.body = body
  }
}

protocol NotificationManagerType: AnyObject {
  init(permissionManager: PermissionManagerType, networkInteractor: NotificationNetworkInteractable)

  var delegate: NotificationManagerDelegate? { get set }
  var networkInteractor: NotificationNetworkInteractable { get }

  func showNotification(with description: NotificationDescription)
  func performRegistrationIfNeeded(forPushToken pushToken: String)

  @discardableResult func removeSubscriptions() -> Promise<Void>
}

protocol NotificationManagerDelegate: AnyObject {
  func localDeviceId(_ manager: NotificationManagerType) -> String
  func persistServerDeviceId(_ serverDeviceId: String)
  func persistDeviceEndpointId(_ deviceEndpointId: String)
  func deleteDeviceEndpointIds()
}

protocol NotificationNetworkInteractable: AnyObject {
  func getDevice(forLocalUUIDString localDeviceId: String) -> Promise<DeviceResponse>
  func getDeviceEndpoints(serverDeviceId: String) -> Promise<[DeviceEndpointResponse]>
  func getWalletSubscriptions() -> Promise<[SubscriptionResponse]>
  func getGeneralSubscriptions(withDeviceEndpointResponse response: DeviceEndpointResponse) -> Promise<GeneralSubscriptionResponse>
  func createDevice(forLocalUUIDString localDeviceId: String) -> Promise<DeviceResponse>
  func createDeviceEndpoint(forPushToken pushToken: String, serverDeviceId: String) -> Promise<DeviceEndpointResponse>
  func subscribeToWalletTopic(withDeviceEndpointResponse response: DeviceEndpointResponse) -> Promise<SubscriptionResponse>
  func subscribeToGeneralTopics(deviceEndpointIds: DeviceEndpointIds, body: GeneralTopicSubscriptionBody) -> Promise<GeneralSubscriptionResponse>
  @discardableResult func removeEndpoints(from responses: [DeviceEndpointResponse]) -> Promise<Void>
}

class NotificationManager: NSObject, NotificationManagerType {
  let permissionManager: PermissionManagerType
  let center: UNUserNotificationCenter

  weak var delegate: NotificationManagerDelegate?
  let networkInteractor: NotificationNetworkInteractable

  private let invitationLogger = OSLog(subsystem: "com.coinninja.notificationManager", category: "invitation_notification")
  private let remoteNotificationLogger = OSLog(subsystem: "com.coinninja.coinkeeper.appcoordinator", category: "remote_notifications")

  required init(permissionManager: PermissionManagerType, networkInteractor: NotificationNetworkInteractable) {
    self.permissionManager = permissionManager
    self.networkInteractor = networkInteractor
    self.center = UNUserNotificationCenter.current()
    super.init()
    self.center.delegate = self
  }

  func showNotification(with description: NotificationDescription) {
    permissionManager.requestPermission(for: .notification) { (status) in
      switch status {
      case .authorized:
        let notification = UNMutableNotificationContent()
        notification.title = description.title
        notification.body = description.body
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: description.identifier, content: notification, trigger: trigger)
        self.center.add(request, withCompletionHandler: nil)
      default: break
      }
    }
  }

  func performRegistrationIfNeeded(forPushToken pushToken: String) {
    guard let delegate = delegate else { return }

    registerDeviceIfNeeded(delegate: delegate)
      .then { self.createDeviceEndpointIfNeeded(withPushToken: pushToken, serverDeviceId: $0.id) }
      .get { self.createWalletSubscriptionIfNeeded(fromDeviceEndpointResponse: $0) }
      .done { self.createGeneralSubscriptionsIfNeeded(fromDeviceEndpointResponse: $0) }
      .catch { os_log("%@: %@", log: self.remoteNotificationLogger, type: .error, #function, $0.localizedDescription) }
  }

  private func registerDeviceIfNeeded(delegate: NotificationManagerDelegate) -> Promise<DeviceResponse> {
    let deviceId = delegate.localDeviceId(self)
    return networkInteractor.getDevice(forLocalUUIDString: deviceId)
      .recover { (error) -> Promise<DeviceResponse> in
        if let networkError = error as? CKNetworkError, case .recordNotFound = networkError {
          return self.networkInteractor.createDevice(forLocalUUIDString: deviceId)
        } else {
          throw error
        }
      }
      .get { delegate.persistServerDeviceId($0.id) }
  }

  private func createDeviceEndpointIfNeeded(withPushToken token: String, serverDeviceId: String) -> Promise<DeviceEndpointResponse> {
    return networkInteractor.getDeviceEndpoints(serverDeviceId: serverDeviceId)
      .filterValues { $0.token == token }
      .then { (responses: [DeviceEndpointResponse]) -> Promise<DeviceEndpointResponse> in
        if let last = responses.last { // not empty
          return Promise.value(last)
        } else {
          return self.networkInteractor.createDeviceEndpoint(forPushToken: token, serverDeviceId: serverDeviceId)
        }
      }
      .get { self.delegate?.persistDeviceEndpointId($0.id) }
  }

  @discardableResult
  private func createWalletSubscriptionIfNeeded(fromDeviceEndpointResponse response: DeviceEndpointResponse) -> Promise<SubscriptionResponse> {
    return networkInteractor.getWalletSubscriptions()
      .filterValues { $0.ownerTypeCase == .wallet && $0.deviceEndpoint.deviceId == response.deviceId }
      .then { (responses: [SubscriptionResponse]) -> Promise<SubscriptionResponse> in
        if let last = responses.last {
          return Promise.value(last)
        } else {
          return self.networkInteractor.subscribeToWalletTopic(withDeviceEndpointResponse: response)
        }
    }
  }

  @discardableResult
  // swiftlint:disable:next line_length
  private func createGeneralSubscriptionsIfNeeded(fromDeviceEndpointResponse response: DeviceEndpointResponse) -> Promise<GeneralSubscriptionResponse> {
    return networkInteractor.getGeneralSubscriptions(withDeviceEndpointResponse: response)
      .then { Promise.value($0.availableTopics) }
      .mapValues { $0.id }
      .then { Promise.value(GeneralTopicSubscriptionBody(topicIds: $0)) }
      .then { self.networkInteractor.subscribeToGeneralTopics(deviceEndpointIds: DeviceEndpointIds(response: response), body: $0)}
  }

  @discardableResult
  func removeSubscriptions() -> Promise<Void> {
    guard let localDeviceID = delegate?.localDeviceId(self) else { return Promise.value(()) }
    return networkInteractor.getDevice(forLocalUUIDString: localDeviceID)
      .then { self.networkInteractor.getDeviceEndpoints(serverDeviceId: $0.id) }
      .then { self.networkInteractor.removeEndpoints(from: $0) }
      .done { self.delegate?.deleteDeviceEndpointIds() }
  }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
    ) {
    DispatchQueue.main.async {
      guard UIApplication.shared.applicationState == .active else { return }
      let invitationIdentifier = response.notification.request.identifier
      os_log("invitationIdentifier: %{private}@", log: self.invitationLogger, type: .debug, invitationIdentifier)
    }
  }
}
