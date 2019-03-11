//
//  MockConnectionManager.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
@testable import DropBit

class MockConnectionManager: ConnectionManagerType {
  func updateOverlay(from viewController: UIViewController, forStatus status: ConnectionManagerStatus, completion: (() -> Void)?) { }

  var noConnectionsViewController: NoConnectionViewController

  weak var delegate: ConnectionManagerDelegate?

  var status: ConnectionManagerStatus

  private(set) var apiUnreachable: Bool
  func setAPIUnreachable(_ unreachable: Bool) {
    apiUnreachable = unreachable
  }

  init() {
    noConnectionsViewController = NoConnectionViewController.makeFromStoryboard()
    status = .connected
    apiUnreachable = false
  }

  func stop() {}

  func start() {}
}
