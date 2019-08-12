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
  func viewControllerDidConfirmTransfer()
}

class WalletTransferViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var transferImageView: UIImageView!
  @IBOutlet var currencySwapView: CurrencySwappableEditAmountView!
  @IBOutlet var confirmView: ConfirmView!

  static func newInstance(delegate: WalletTransferViewControllerDelegate) -> WalletTransferViewController {
    let viewController = WalletTransferViewController.makeFromStoryboard()
    viewController.generalCoordinationDelegate = delegate
    return viewController
  }

  var coordinationDelegate: WalletTransferViewControllerDelegate? {
    return generalCoordinationDelegate as? WalletTransferViewControllerDelegate
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    confirmView.delegate = self
  }
}

extension WalletTransferViewController: ConfirmViewDelegate {

  func viewDidConfirm() {
    coordinationDelegate?.viewControllerDidConfirmTransfer()
  }
}
