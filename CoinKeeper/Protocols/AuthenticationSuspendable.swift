//
//  AuthenticationSuspendable.swift
//  DropBit
//
//  Created by BJ Miller on 5/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol AuthenticationSuspendable: AnyObject {
  var suspendAuthenticationOnceUntil: Date? { get set }
  func viewControllerRequestedAuthenticationSuspension(_ viewController: UIViewController)
}

extension AuthenticationSuspendable {
  func viewControllerRequestedAuthenticationSuspension(_ viewController: UIViewController) {
    guard let suspendUntilDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) else { return }
    log.debug("Will suspend authentication until \(suspendUntilDate.debugDescription) or next open")
    self.suspendAuthenticationOnceUntil = suspendUntilDate
  }
}
