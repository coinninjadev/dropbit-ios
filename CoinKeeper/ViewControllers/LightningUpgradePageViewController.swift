//
//  LightningUpgradePageViewController.swift
//  DropBit
//
//  Created by BJ Miller on 8/30/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import CNBitcoinKit

final class LightningUpgradePageViewController: UIPageViewController, StoryboardInitializable {

  weak var generalCoordinationDelegate: AnyObject?

  var transactionData: CNBTransactionData? {
    didSet {
      if let data = transactionData {
        lnViewControllers
          .first
          .flatMap { $0 as? LightningUpgradeStartViewController }?
          .updateUI(withTransactionData: data)
      }
    }
  }
  private func performUpgradeNowAction() {
    self.setViewControllers([lnViewControllers[1]], direction: .forward, animated: true, completion: nil)
    // this will need to kick off the tx broadcast, but status VC can't dismiss till tx is broadcast, if there is a tx to broadcast
  }

  private func showFinalizeUpgradeAction() {
    self.setViewControllers([lnViewControllers[2]], direction: .forward, animated: true, completion: nil)
  }

  private(set) lazy var lnViewControllers: [UIViewController] = {
    [
      (generalCoordinationDelegate as? LightningUpgradeStartViewControllerDelegate)
        .map {
          LightningUpgradeStartViewController.newInstance(
            withDelegate: $0,
            nextStep: { [weak self] in self?.performUpgradeNowAction() }
          )
        }
//      (generalCoordinationDelegate as? LightningUpgradeStatusViewControllerDelegate)
//        .map {
//          LightningUpgradeStatusViewController.newInstance(
//            withDelegate: $0,
//            nextAction: { [weak self] in self?.showFinalizeUpgradeAction() }
//          )
//        }
//      (generalCoordinationDelegate as? LightningUpgradeStartViewControllerDelegate).map { LightningUpgradeStartViewController.newInstance(withDelegate: $0) }
      ].compactMap { $0 }
  }()

  static func newInstance(withGeneralCoordinationDelegate delegate: AnyObject) -> LightningUpgradePageViewController {
    let controller = LightningUpgradePageViewController.makeFromStoryboard()
    controller.generalCoordinationDelegate = delegate
    return controller
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    modalPresentationStyle = .overFullScreen
    modalTransitionStyle = .coverVertical

    lnViewControllers.first.map { self.setViewControllers([$0], direction: .forward, animated: true, completion: nil) }
  }

  func updateUI(with data: CNBTransactionData?) {
    lnViewControllers.first.flatMap { $0 as? LightningUpgradeStartViewController }?.updateUI(withTransactionData: data)
  }

}
