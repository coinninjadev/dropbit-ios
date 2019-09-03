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
  func viewController(_ viewController: LightningUpgradeStatusViewController, broadcast encodedTx: String) -> Promise<Void>
}

protocol LightningUpgradeStatusDataSource: AnyObject {
  var transactionData: CNBTransactionData? { get }
}

final class LightningUpgradeStatusViewController: BaseViewController, StoryboardInitializable {

  var coordinationDelegate: LightningUpgradeStatusViewControllerDelegate? {
    return generalCoordinationDelegate as? LightningUpgradeStatusViewControllerDelegate
  }

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
    controller.generalCoordinationDelegate = delegate
    controller.dataSource = dataSource
    controller.nextStep = nextStep
    return controller
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    styleInitialUI()

    guard let coordinator = coordinationDelegate else { return }
    // create new wallet
    coordinationDelegate?.viewControllerStartUpgradingWallet(self)
      .get { self.finishedCreatingNewWallet() }

    // update to segwit
      .then { _ in coordinator.viewControllerStartUpgradingToSegwit(self) }
      .get { _ in self.finishedUpdatingToSegwit() }

    // transfer funds
      .done { _ in self.transferFundsIfNeeded() }
      .cauterize()
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
    guard let coordinator = coordinationDelegate,
      let wallet = coordinator.viewControllerDidRequestUpgradedWallet(self)
      else { return }

    guard let data = dataSource.transactionData, data.amount != 0 else {
      nextStep?(nil)
      return
    }

    let builder = CNBTransactionBuilder()

    let encodedTx = builder.generateTxMetadata(with: data, wallet: wallet).encodedTx
    self.encodedTx = encodedTx
    coordinator.viewController(self, broadcast: encodedTx)
      .done { (_) in
        self.finishedTransferringFunds()
        self.nextStep?(nil)
      }.catch { (error: Error) in
        self.nextStep?(error)
    }
  }

  private func finishedCreatingNewWallet() {
    creatingNewWalletStatusImageView.image = completedImage
  }

  private func finishedUpdatingToSegwit() {
    updatingToSegwitStatusImageView.image = completedImage
  }

  private func finishedTransferringFunds() {
    transferringFundsStatusImageView.image = completedImage
  }

}
