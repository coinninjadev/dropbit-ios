//
//  AuthenticationSuspendable.swift
//  DropBit
//
//  Created by BJ Miller on 5/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import os.log

protocol AuthenticationSuspendable: AnyObject {
  var suspendAuthenticationOnceUntil: Date? { get set }
  func viewControllerRequestedAuthenticationSuspension(_ viewController: UIViewController)
}

extension AuthenticationSuspendable {
  func viewControllerRequestedAuthenticationSuspension(_ viewController: UIViewController) {
    guard let suspendUntilDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) else { return }
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.authenticationSuspendable", category: "suspending")
    os_log("Will suspend authentication until %@ or next open", log: logger, type: .debug, suspendUntilDate as CVarArg)
    self.suspendAuthenticationOnceUntil = suspendUntilDate
  }
}
