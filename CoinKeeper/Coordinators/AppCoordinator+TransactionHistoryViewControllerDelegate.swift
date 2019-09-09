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

  func viewControllerShouldSeeTransactionDetails(for object: TransactionDetailCellDisplayable) {
    let viewController = TransactionPopoverDetailsViewController.newInstance(delegate: self)
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
    //TODO:
//    switch viewController.viewModel.walletTransactionType {
//    case .lightning:
//      let controller = TransactionHistoryDetailsViewController.newInstance(withDelegate: self,
//                                                                           fetchedResultsController: viewController.lightningFetchResultsController,
//                                                                           selectedIndexPath: indexPath,
//                                                                           viewModelForIndexPath: { viewController.detailViewModel(at: $0) },
//                                                                           urlOpener: self)
//      viewController.present(controller, animated: true, completion: nil)
//    case .onChain:
//      let controller = TransactionHistoryDetailsViewController.newInstance(withDelegate: self,
//                                                                           fetchedResultsController: viewController.onChainFetchResultsController,
//                                                                           selectedIndexPath: indexPath,
//                                                                           viewModelForIndexPath: { viewController.detailViewModel(at: $0) },
//                                                                           urlOpener: self)
//      viewController.present(controller, animated: true, completion: nil)
//    }
  }

  func viewControllerDidDismissTransactionDetails(_ viewController: UIViewController) {
    viewController.dismiss(animated: true, completion: nil)
  }

  func summaryHeaderType(for viewController: UIViewController) -> SummaryHeaderType? {
    if wordsBackedUp {
      return nil
    } else {
      return .backUpWallet
    }
  }

  func viewControllerDidSelectSummaryHeader(_ viewController: UIViewController) {
    guard let headerType = summaryHeaderType(for: viewController) else { return }
    switch headerType {
    case .backUpWallet:
      self.showWordRecoveryFlow()
    }
  }

}
