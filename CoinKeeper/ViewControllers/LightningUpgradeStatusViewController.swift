//
//  LightningUpgradeStatusViewController.swift
//  DropBit
//
//  Created by BJ Miller on 8/30/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import CNBitcoinKit
import PromiseKit

protocol LightningUpgradeStatusViewControllerDelegate: AnyObject {
  func viewControllerDidRequestUpgradedWallet(_ viewController: LightningUpgradeStatusViewController) -> CNBHDWallet
  func viewController(_ viewController: LightningUpgradeStatusViewController, broadcast encodedTx: String) -> Promise<Void>
}

final class LightningUpgradeStatusViewController: BaseViewController, StoryboardInitializable {

  var coordinationDelegate: LightningUpgradeStatusViewControllerDelegate? {
    return generalCoordinationDelegate as? LightningUpgradeStatusViewControllerDelegate
  }

  weak var transactionData: CNBTransactionData?
  var encodedTx: String?
  private var nextStep: CKErrorCompletion?

  static func newInstance(
    withDelegate delegate: LightningUpgradeStatusViewControllerDelegate,
    transactionData: CNBTransactionData?,
    nextStep: @escaping CKErrorCompletion
    ) -> LightningUpgradeStatusViewController {
    let controller = LightningUpgradeStatusViewController.makeFromStoryboard()
    controller.generalCoordinationDelegate = delegate
    controller.transactionData = transactionData
    controller.nextStep = nextStep
    return controller
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // animate first, create new wallet

    // animate second, update to segwit

    // animate third, transfer funds
    transferFundsIfNeeded()
  }

  private func transferFundsIfNeeded() {
    guard let coordinator = coordinationDelegate else { return }

    guard let data = transactionData, data.amount != 0 else {
      nextStep?(nil)
      return
    }

    let builder = CNBTransactionBuilder()

    let wallet = coordinator.viewControllerDidRequestUpgradedWallet(self)
    let encodedTx = builder.generateTxMetadata(with: data, wallet: wallet).encodedTx
    self.encodedTx = encodedTx
    coordinator.viewController(self, broadcast: encodedTx)
      .done { (_) in
        self.nextStep?(nil)
      }.catch { (error: Error) in
        self.nextStep?(error)
    }
  }

}
