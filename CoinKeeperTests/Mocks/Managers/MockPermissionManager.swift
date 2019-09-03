//
//  MockPermissionManager.swift
//  DropBitTests
//
//  Created by Mitchell Malleo on 4/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Permission
@testable import DropBit

class MockPermissionManager: PermissionManagerType {
  var requestPermissionCompletionCalled: Bool = false

  func permissionStatus(for kind: PermissionKind) -> PermissionStatus {
    return .authorized
  }

  func requestPermission(for kind: PermissionKind, completion: @escaping (PermissionStatus) -> Void) {
    completion(.disabled)
  }

  func refreshNotificationPermissionStatus() {}

}
