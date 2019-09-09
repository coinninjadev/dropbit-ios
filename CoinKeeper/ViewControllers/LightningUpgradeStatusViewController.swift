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
  func viewControllerDidRequestUpgradedWallet(_ viewController: LightningUpgradeStatusViewController) -> CNBHDWallet?

  func viewControllerStartUpgradingWallet(_ viewController: LightningUpgradeStatusViewController) -> Promise<Void>
  func viewControllerStartUpgradingToSegwit(_ viewController: LightningUpgradeStatusViewController) -> Promise<Void>
  func viewController(_ viewController: LightningUpgradeStatusViewController, broadcast data: CNBTransactionData) -> Promise<String>
}

protocol LightningUpgradeStatusDataSource: AnyObject {
  var transactionData: CNBTransactionData? { get }
}

final class LightningUpgradeStatusViewController: BaseViewController, StoryboardInitializable {

  private(set) weak var delegate: LightningUpgradeStatusViewControllerDelegate!

  var dataSource: LightningUpgradeStatusDataSource!

  @IBOutlet var overlayView: LightningUpgradeGradientOverlayView!
  @IBOutlet var creatingNewWalletStatusImageView: UIImageView!
  @IBOutlet var creatingNewWalletStatusLabel: UILabel!
  @IBOutlet var updatingToSegwitStatusImageView: UIImageView!
  @IBOutlet var updatingToSegwitStatusLabel: UILabel!
  @IBOutlet var transferringFundsStatusImageView: UIImageView!
  @IBOutlet var transferringFundsStatusLabel: UILabel!
  @IBOutlet var doNotCloseLabel: UILabel!

  var encodedTx: String?
  private var nextStep: CKErrorCompletion?

  private let notStartedImage = UIImage(imageLiteralResourceName: "circleCheckPurple")
  private let completedImage = UIImage(imageLiteralResourceName: "circleCheckGreen")

  static func newInstance(
    withDelegate delegate: LightningUpgradeStatusViewControllerDelegate,
    dataSource: LightningUpgradeStatusDataSource,
    nextStep: @escaping CKErrorCompletion
    ) -> LightningUpgradeStatusViewController {
    let controller = LightningUpgradeStatusViewController.makeFromStoryboard()
    controller.delegate = delegate
    controller.dataSource = dataSource
    controller.nextStep = nextStep
    return controller
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    styleInitialUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    // create new wallet
    delegate.viewControllerStartUpgradingWallet(self)
      .then { self.finishedCreatingNewWallet() }

    // update to segwit
      .then { _ in self.delegate.viewControllerStartUpgradingToSegwit(self) }
      .then { _ in self.finishedUpdatingToSegwit() }

    // transfer funds
      .done { _ in self.transferFundsIfNeeded() }
      .catch { (error: Error) in
        log.error(error, message: "Failed during Segwit upgrade")
        // show alert
    }
  }

  private func styleInitialUI() {
    [creatingNewWalletStatusImageView, updatingToSegwitStatusImageView, transferringFundsStatusImageView]
      .forEach { $0.image = self.notStartedImage }

    creatingNewWalletStatusLabel.text = "Creating new wallet"
    updatingToSegwitStatusLabel.text = "Updating to SegWit"
    transferringFundsStatusLabel.text = "Transferring funds"

    [creatingNewWalletStatusLabel, updatingToSegwitStatusLabel, transferringFundsStatusLabel]
      .forEach { label in
        label?.font = .regular(15)
        label?.textColor = .white
    }

    doNotCloseLabel.textColor = .darkPeach
    doNotCloseLabel.text = "DO NOT CLOSE"
    doNotCloseLabel.font = .regular(13)
  }

  private func transferFundsIfNeeded() {
    guard let data = dataSource.transactionData, data.amount != 0 else {
      nextStep?(nil)
      return
    }

    delegate.viewController(self, broadcast: data)
      .then { _ in self.finishedTransferringFunds() }
      .done { _ in self.nextStep?(nil) }
      .catch { (error: Error) in
        self.nextStep?(error)
    }
  }

  private func finishedCreatingNewWallet() -> Promise<Void> {
    return Promise { seal in
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        self.creatingNewWalletStatusImageView.image = self.completedImage
        seal.fulfill(())
      }
    }
  }

  private func finishedUpdatingToSegwit() -> Promise<Void> {
    return Promise { seal in
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        self.updatingToSegwitStatusImageView.image = self.completedImage
        seal.fulfill(())
      }
    }
  }

  private func finishedTransferringFunds() -> Promise<Void> {
    return Promise { seal in
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        self.transferringFundsStatusImageView.image = self.completedImage
        seal.fulfill(())
      }
    }
  }

}
