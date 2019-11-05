//
//  DebugDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/4/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol DebugDelegate: class {
  func viewControllerSendDebuggingInfo(_ viewController: UIViewController)
}
