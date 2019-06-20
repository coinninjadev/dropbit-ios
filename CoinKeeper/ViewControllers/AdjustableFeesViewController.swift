//
//  AdjustableFeesViewController.swift
//  DropBit
//
//  Created by Ben Winters on 6/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

enum TransactionFeeMode: Int {
  case fast = 1 //UserDefaults returns 0 by default, 1 allows us to distinguish
  case slow
  case cheap

  static var defaultMode: TransactionFeeMode {
    return .fast
  }

  static func mode(for int: Int) -> TransactionFeeMode {
    return TransactionFeeMode(rawValue: int) ?? .defaultMode
  }

}

protocol AdjustableFeesViewControllerDelegate: AnyObject {

  var adjustableFeesIsEnabled: Bool { get }
  var preferredTransactionFeeMode: TransactionFeeMode { get }
  func viewController(_ viewController: UIViewController, didSelectFeeMode: TransactionFeeMode)

}

class AdjustableFeesViewController: BaseViewController, StoryboardInitializable {

  weak var delegate: AdjustableFeesViewControllerDelegate!

  static func newInstance(delegate: AdjustableFeesViewControllerDelegate) -> AdjustableFeesViewController {
    let vc = AdjustableFeesViewController.makeFromStoryboard()
    vc.delegate = delegate
    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.title = "ADJUSTABLE FEES"
    
  }

}
