//
//  NotificationToken.swift
//  DropBit
//
//  Created by Bill Feth on 4/11/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

// See https://oleb.net/blog/2018/01/notificationcenter-removeobserver/

/// Wraps the observer token received from
/// NotificationCenter.addObserver(forName:object:queue:using:)
/// and unregisters it in deinit.
public class NotificationToken: NSObject {
  let notificationCenter: NotificationCenter
  let token: Any

  init(notificationCenter: NotificationCenter = .default, token: Any) {
    self.notificationCenter = notificationCenter
    self.token = token
  }

  deinit {
    notificationCenter.removeObserver(token)
  }
}
