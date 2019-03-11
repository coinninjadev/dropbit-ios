//
//  AppCoordinator+TransactionHistoryViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 6/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit
import UIKit

extension AppCoordinator: TransactionHistoryViewControllerDelegate {

  func viewControllerDidTapAddMemo(_ viewController: UIViewController,
                                   with completion: @escaping (String) -> Void) {
    let memoViewController = MemoEntryViewController.makeFromStoryboard()
    memoViewController.backgroundImage = UIApplication.shared.screenshot()
    assignCoordinationDelegate(to: memoViewController)
    memoViewController.completion = completion
    viewController.present(memoViewController, animated: true)
  }

  func viewControllerShouldUpdateTransaction(_ viewController: TransactionHistoryViewController, transaction: CKMTransaction) -> Promise<Void> {
    return Promise { seal in
      let context = transaction.managedObjectContext
      context?.performAndWait {
        do {
          try context?.save()
          viewController.collectionViews.forEach { $0.reloadData() }
          seal.fulfill(())
        } catch {
          seal.reject(error)
        }
      }
    }
  }

  func viewControllerDidRequestTutorial(_ viewController: UIViewController) {
    analyticsManager.track(event: .userDidOpenTutorial, with: nil)
    let viewController = TutorialViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: viewController)
    viewController.urlOpener = self
    viewController.modalPresentationStyle = .formSheet
    navigationController.present(viewController, animated: true, completion: nil)
  }

  func viewControllerAttemptedToRefreshTransactions(_ viewController: UIViewController) {
    serialQueueManager.enqueueOptionalIncrementalSync()
  }

  func viewControllerShouldSeeTransactionDetails(for viewModel: TransactionHistoryDetailCellViewModel) {
    let viewController = TransactionPopoverDetailsViewController.makeFromStoryboard()
    viewController.viewModel = viewModel
    assignCoordinationDelegate(to: viewController)
    viewController.modalPresentationStyle = .overFullScreen
    viewController.modalTransitionStyle = .crossDissolve
    navigationController.topViewController()?.present(viewController, animated: true, completion: nil)
  }

  func viewControllerDidCancelDropbit() {
    analyticsManager.track(event: .cancelDropbitPressed, with: nil)
  }

  func viewController(_ viewController: TransactionHistoryViewController, didCancelInvitationWithID invitationID: String, at indexPath: IndexPath) {
    guard let walletWorker = createWalletAddressDataWorker() else { return }
    let context = persistenceManager.createBackgroundContext()
    context.performAndWait {
      walletWorker.cancelInvitation(withID: invitationID, in: context)
        .done(in: context) {
          context.performAndWait {
            try? context.save()
          }

          DispatchQueue.main.async {
            // Manual reloading is necessary because the frc will not automatically reload
            // since the status change is made to the related invitation and not the transaction.
            viewController.reloadTransactions(atIndexPaths: [indexPath])
          }
        }
        .catch { error in
          self.alertManager.showError(message: "Failed to cancel invitation.\nError details: \(error.localizedDescription)", forDuration: 5.0)
      }
    }
  }

  func viewControllerDidRequestHistoryUpdate(_ viewController: TransactionHistoryViewController) {
    serialQueueManager.enqueueOptionalIncrementalSync()
  }

  func viewControllerDidDisplayTransactions(_ viewController: TransactionHistoryViewController) {
    badgeManager.setTransactionsDidDisplay()
  }

}
