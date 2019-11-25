//
//  PermissionManager.swift
//  DropBit
//
//  Created by Mitchell Malleo on 4/11/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Permission
import UserNotifications

enum PermissionKind {
  case contacts
  case photos
  case camera
  case notification
  case location
}

protocol PermissionManagerType {
  func permissionStatus(for kind: PermissionKind) -> PermissionStatus
  func requestPermission(for kind: PermissionKind, completion: @escaping (PermissionStatus) -> Void)
  func refreshNotificationPermissionStatus()
}

class PermissionManager: PermissionManagerType {

  /// Cached in memory to allow for synchronous checks
  private var notificationStatus: PermissionStatus = .authorized

  func refreshNotificationPermissionStatus() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      let authStatus = settings.authorizationStatus
      switch authStatus {
      case .notDetermined:  self.notificationStatus = .notDetermined
      case .denied:         self.notificationStatus = .denied
      case .authorized:     self.notificationStatus = .authorized
      case .provisional:    self.notificationStatus = .authorized
      @unknown default:     self.notificationStatus = .authorized
      }
      log.debug("Refreshed notification permission status: \(self.notificationStatus.rawValue), \(authStatus.rawValue)")
    }
  }

  func requestPermission(for kind: PermissionKind, completion: @escaping (PermissionStatus) -> Void) {
    var permission: Permission

    switch kind {
    case .photos: permission = Permission.photos
    case .contacts: permission = Permission.contacts
    case .camera:   permission = Permission.camera
    case .location: permission = Permission.locationWhenInUse

    case .notification:
      switch notificationStatus {
      case .notDetermined:
        permission = Permission.notifications

      default:
        completion(notificationStatus)
        return //Exit early to avoid having Permission perform the request based on a deprecated API
      }
    }

    permission.request { status in
      if kind == .notification {
        self.refreshNotificationPermissionStatus()
      }
      completion(status)
    }
  }

  func permissionStatus(for kind: PermissionKind) -> PermissionStatus {
    switch kind {
    case .photos:
      return Permission.photos.status
    case .contacts:
      return Permission.contacts.status
    case .camera:
      return Permission.camera.status
    case .notification:
      return notificationStatus
    case .location:
      return Permission.locationWhenInUse.status
    }
  }

}
