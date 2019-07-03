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
  var delegate: NotificationManagerDelegate? { get set }
  var networkInteractor: NotificationNetworkInteractable { get }

  func showNotification(with description: NotificationDescription)
  func performRegistrationIfNeeded(forPushToken pushToken: String)

  @discardableResult func removeSubscriptions() -> Promise<Void>

  @discardableResult func unsubscribeFromTopic(type: SubscriptionTopicType) -> Promise<Void>
  @discardableResult func subscribeToTopic(type: SubscriptionTopicType) -> Promise<Void>
}

protocol NotificationManagerDelegate: AnyObject {
  func localDeviceId(_ manager: NotificationManagerType) -> String
  func persistServerDeviceId(_ serverDeviceId: String)
  func persistDeviceEndpointId(_ deviceEndpointId: String)
  func deleteDeviceEndpointIds()
  func shouldSubscribeToTopic(withName name: String) -> Bool
  func pushToken() -> String?
  func updateNotificationEnabled(_ enabled: Bool, forType type: SubscriptionTopicType)
  @discardableResult func unsubscribeFromTopic(type: SubscriptionTopicType, deviceEndpointIds: DeviceEndpointIds) -> Promise<Void>
  @discardableResult func subscribeToTopic(type: SubscriptionTopicType, deviceEndpointIds: DeviceEndpointIds) -> Promise<Void>
}

protocol NotificationNetworkInteractable: AnyObject {
  func getDevice(forLocalUUIDString localDeviceId: String) -> Promise<DeviceResponse>
  func getDeviceEndpoints(serverDeviceId: String) -> Promise<[DeviceEndpointResponse]>
  func getWalletSubscriptions() -> Promise<[SubscriptionResponse]>
  func getSubscriptionInfo(withDeviceEndpointResponse response: DeviceEndpointResponse) -> Promise<SubscriptionInfoResponse>
  func getSubscriptionInfo(withDeviceEndpointIds endpointIds: DeviceEndpointIds) -> Promise<SubscriptionInfoResponse>
  func createDevice(forLocalUUIDString localDeviceId: String) -> Promise<DeviceResponse>
  func createDeviceEndpoint(forPushToken pushToken: String, serverDeviceId: String) -> Promise<DeviceEndpointResponse>
  func subscribeToWalletTopic(withDeviceEndpointResponse response: DeviceEndpointResponse) -> Promise<SubscriptionResponse>
  @discardableResult func subscribeToTopics(
    deviceEndpointIds: DeviceEndpointIds,
    body: NotificationTopicSubscriptionBody) -> Promise<Void>
  @discardableResult func removeEndpoints(from responses: [DeviceEndpointResponse]) -> Promise<Void>
  @discardableResult func unsubscribeFromTopic(topicId: String, deviceEndpointIds: DeviceEndpointIds) -> Promise<Void>
}

class NotificationManager: NSObject, NotificationManagerType {
  let permissionManager: PermissionManagerType
  let center: UNUserNotificationCenter

  weak var delegate: NotificationManagerDelegate?
  let networkInteractor: NotificationNetworkInteractable

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
      .then { self.createSubscriptionsIfNeeded(fromDeviceEndpointResponse: $0) }
      .catch { log.error($0, message: nil) }
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
    return deviceEndpointResponse(token: token)
      .get { self.delegate?.persistDeviceEndpointId($0.id) }
  }

  @discardableResult
  private func createSubscriptionsIfNeeded(fromDeviceEndpointResponse response: DeviceEndpointResponse) -> Promise<Void> {
    return createWalletSubscriptionIfNeeded(fromDeviceEndpointResponse: response)
      .then { _ in self.networkInteractor.getSubscriptionInfo(withDeviceEndpointResponse: response) }
      .then { _ in self.createNotificationSubscriptionsIfNeeded(fromDeviceEndpointResponse: response) }
      .asVoid()
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
  private func createNotificationSubscriptionsIfNeeded(
    fromDeviceEndpointResponse response: DeviceEndpointResponse
    ) -> Promise<Void> {
    guard let localDelegate = delegate else { return Promise(error: CKPersistenceError.missingValue(key: "notificationManagerDelegate")) }
    return networkInteractor.getSubscriptionInfo(withDeviceEndpointResponse: response)
      .then { (subInfoResponse: SubscriptionInfoResponse) -> Promise<[SubscriptionAvailableTopicResponse]> in
        let subscribedIds = subInfoResponse.subscriptions.map { $0.ownerId }.asSet()
        let availableIds = subInfoResponse.availableTopics.map { $0.id }.asSet()
        let unsubscribedIds = availableIds.subtracting(subscribedIds)
        let topics = subInfoResponse.availableTopics.filter { unsubscribedIds.contains($0.id) }
        return Promise.value(topics)
      }
      .filterValues { localDelegate.shouldSubscribeToTopic(withName: $0.name) }
      .mapValues { $0.id }
      .then { (ids: [String]) -> Promise<Void> in
        guard ids.isNotEmpty else { return Promise.value(()) }
        let body = NotificationTopicSubscriptionBody(topicIds: ids)
        let deviceEndpointIds = DeviceEndpointIds(response: response)
        return self.networkInteractor.subscribeToTopics(deviceEndpointIds: deviceEndpointIds, body: body)
      }
      .then { self.syncKnownSubscriptions(response: response) }
  }

  private func syncKnownSubscriptions(response: DeviceEndpointResponse) -> Promise<Void> {
    return networkInteractor.getSubscriptionInfo(withDeviceEndpointResponse: response)
      .done { (subInfoResponse: SubscriptionInfoResponse) in
        self.updateLocallyKnownSubscriptions(with: subInfoResponse)
    }
  }

  private func updateLocallyKnownSubscriptions(with subscriptionInfo: SubscriptionInfoResponse) {
    let subscriptions = subscriptionInfo.subscriptions
    let availableTopics = subscriptionInfo.availableTopics
    for availableTopic in availableTopics {
      let isEnabled = subscriptions.first(where: { $0.ownerId == availableTopic.id }) != nil
      delegate?.updateNotificationEnabled(isEnabled, forType: availableTopic.type)
    }
  }

  @discardableResult
  func subscribeToTopic(type: SubscriptionTopicType) -> Promise<Void> {
    guard let delegate = delegate else { return Promise(error: CKPersistenceError.missingValue(key: "delegate")) }
    return self.deviceEndpointResponse()
      .then { delegate.subscribeToTopic(type: type, deviceEndpointIds: DeviceEndpointIds(response: $0)) }
  }

  @discardableResult
  func unsubscribeFromTopic(type: SubscriptionTopicType) -> Promise<Void> {
    guard let delegate = delegate else { return Promise(error: CKPersistenceError.missingValue(key: "delegate")) }
    return self.deviceEndpointResponse()
      .then { delegate.unsubscribeFromTopic(type: type, deviceEndpointIds: DeviceEndpointIds(response: $0)) }
  }

  private func deviceEndpointResponse(token: String? = nil) -> Promise<DeviceEndpointResponse> {
    guard let localDelegate = delegate else { return Promise(error: CKPersistenceError.missingValue(key: "delegate")) }
    let localDeviceID = localDelegate.localDeviceId(self)
    let maybeToken = token ?? localDelegate.pushToken()
    guard let localToken = maybeToken else { return Promise(error: CKPersistenceError.missingValue(key: "push token")) }
    var serverDeviceId = ""
    return networkInteractor.getDevice(forLocalUUIDString: localDeviceID)
      .get { serverDeviceId = $0.id }
      .then { self.networkInteractor.getDeviceEndpoints(serverDeviceId: $0.id) }
      .filterValues { $0.token == localToken }
      .then { (responses: [DeviceEndpointResponse]) -> Promise<DeviceEndpointResponse> in
        if let last = responses.last { // not empty
          return Promise.value(last)
        } else {
          return self.networkInteractor.createDeviceEndpoint(forPushToken: localToken, serverDeviceId: serverDeviceId)
        }
    }

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
      log.debug("invitationIdentifier: %@", privateArgs: [invitationIdentifier])
    }
  }
}
