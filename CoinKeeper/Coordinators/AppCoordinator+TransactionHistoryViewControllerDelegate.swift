//
//  AppCoordinator+TransactionHistoryViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 6/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit
import UIKit
import MMDrawerController

extension AppCoordinator: TransactionHistoryViewControllerDelegate {

  func viewControllerDidTapAddMemo(_ viewController: UIViewController,
                                   with completion: @escaping (String) -> Void) {
    let background = UIApplication.shared.screenshot()
    let memoViewController = MemoEntryViewController.newInstance(delegate: self,
                                                                 backgroundImage: background,
                                                                 completion: completion)
    viewController.present(memoViewController, animated: true)
  }

  func viewControllerDidRequestTutorial(_ viewController: UIViewController) {
    analyticsManager.track(event: .userDidOpenTutorial, with: nil)
    let viewController = TutorialViewController.newInstance(delegate: self, urlOpener: self)
    viewController.modalPresentationStyle = .formSheet
    navigationController.present(viewController, animated: true, completion: nil)
  }

  func viewControllerDidTapGetBitcoin(_ viewController: UIViewController) {
    analyticsManager.track(event: .getBitcoinButtonPressed, with: nil)
    let controller = GetBitcoinViewController.newInstance(delegate: self)
    navigationController.pushViewController(controller, animated: true)
  }

  func viewControllerDidTapSpendBitcoin(_ viewController: UIViewController) {
    analyticsManager.track(event: .spendBitcoinButtonPressed, with: nil)
    let controller = SpendBitcoinViewController.newInstance(delegate: self)
    navigationController.pushViewController(controller, animated: true)
  }

  func viewControllerAttemptedToRefreshTransactions(_ viewController: UIViewController) {
    serialQueueManager.enqueueOptionalIncrementalSync()
  }

  func viewControllerShouldSeeTransactionDetails(for viewModel: OldTransactionDetailCellViewModel) {
    let viewController = TransactionPopoverDetailsViewController.newInstance(delegate: self, viewModel: viewModel)
    viewController.modalPresentationStyle = .overFullScreen
    viewController.modalTransitionStyle = .crossDissolve
    navigationController.topViewController()?.present(viewController, animated: true, completion: nil)
  }

  func viewControllerDidRequestHistoryUpdate(_ viewController: TransactionHistoryViewController) {
    serialQueueManager.enqueueOptionalIncrementalSync()
  }

  func viewControllerDidDisplayTransactions(_ viewController: TransactionHistoryViewController) {
    badgeManager.setTransactionsDidDisplay()
  }

  func viewControllerSummariesDidReload(_ viewController: TransactionHistoryViewController, indexPathsIfNotAll paths: [IndexPath]?) {
    guard let detailsVC = navigationController
      .topViewController() as? TransactionHistoryDetailsViewController else { return }
    if let paths = paths {
      detailsVC.collectionView.reloadItems(at: paths)
    } else {
      detailsVC.collectionView.reloadData()
    }
  }

  func viewController(_ viewController: TransactionHistoryViewController, didSelectItemAtIndexPath indexPath: IndexPath) {
    let controller = TransactionHistoryDetailsViewController.newInstance(withDelegate: self,
                                                                         walletTxType: viewController.viewModel.walletTransactionType,
                                                                         selectedIndexPath: indexPath,
                                                                         dataSource: viewController.viewModel.dataSource)
    viewController.present(controller, animated: true, completion: nil)
  }

  func viewControllerDidDismissTransactionDetails(_ viewController: UIViewController) {
    viewController.dismiss(animated: true, completion: nil)
  }

  func summaryHeaderType(for viewController: UIViewController) -> SummaryHeaderType? {
    if wordsBackedUp || backupWarningDelayInEffect {
      return nil
    } else {
      return .backUpWallet
    }
  }

  private var backupWarningDelayInEffect: Bool {
    if uiTestIsInProgress { return false }
    guard let firstOpen = self.persistenceManager.brokers.activity.firstOpenDate else { return true }
    let delayEndDate = firstOpen.addingTimeInterval(.oneDay)
    return delayEndDate > Date()
  }

  func viewControllerDidSelectSummaryHeader(_ viewController: UIViewController) {
    guard let headerType = summaryHeaderType(for: viewController) else { return }
    switch headerType {
    case .backUpWallet:
      self.showWordRecoveryFlow()
    }
  }

}
