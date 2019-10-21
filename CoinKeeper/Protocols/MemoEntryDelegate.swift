//
//  MemoEntryDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 10/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol MemoEntryDelegate {
  func viewControllerDidSelectMemoButton(_ viewController: UIViewController, memo: String?, completion: @escaping (String) -> Void)
}
