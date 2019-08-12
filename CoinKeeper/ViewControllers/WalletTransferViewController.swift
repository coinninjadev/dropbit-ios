//
//  WalletTransferViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol WalletTransferViewControllerDelegate: class {
  func viewControllerDidConfirmTransaction()
}

class WalletTransferViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var transferImageView: UIImageView!
  @IBOutlet var currencySwapView: CurrencySwappableEditAmountView!
  @IBOutlet var tapAndHoldLabel: UILabel!
  @IBOutlet var confirmButton: ConfirmPaymentButton!

}
