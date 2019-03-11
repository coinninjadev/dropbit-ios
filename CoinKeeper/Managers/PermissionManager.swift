//
//  PermissionManager.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 4/11/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Permission

enum PermissionKind {
  case contacts
  case camera
  case notification
}

protocol PermissionManagerType {
  func permissionStatus(for kind: PermissionKind) -> PermissionStatus
  func requestPermission(for kind: PermissionKind, completion: @escaping (PermissionStatus) -> Void)
}

class PermissionManager: PermissionManagerType {
  func requestPermission(for kind: PermissionKind, completion: @escaping (PermissionStatus) -> Void) {
    var permission: Permission

    switch kind {
    case .contacts:
      permission = Permission.contacts
    case .camera:
      permission = Permission.camera
    case .notification:
      permission = Permission.notifications
    }

    permission.request { status in
      completion(status)
    }
  }

  func permissionStatus(for kind: PermissionKind) -> PermissionStatus {
    switch kind {
    case .contacts:
      return Permission.contacts.status
    case .camera:
      return Permission.camera.status
    case .notification:
      return Permission.notifications.status
    }
  }
}
