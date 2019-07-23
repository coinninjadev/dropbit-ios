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

  func viewControllerDidRequestTutorial(_ viewController: UIViewController) {
    analyticsManager.track(event: .userDidOpenTutorial, with: nil)
    let viewController = TutorialViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: viewController)
    viewController.urlOpener = self
    viewController.modalPresentationStyle = .formSheet
    navigationController.present(viewController, animated: true, completion: nil)
  }

  func viewControllerDidTapGetBitcoin(_ viewController: UIViewController) {
    analyticsManager.track(event: .getBitcoinButtonPressed, with: nil)
    let controller = GetBitcoinViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: controller)
    navigationController.pushViewController(controller, animated: true)
  }

  func viewControllerDidTapSpendBitcoin(_ viewController: UIViewController) {
    analyticsManager.track(event: .spendBitcoinButtonPressed, with: nil)
    let controller = SpendBitcoinViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: controller)
    navigationController.pushViewController(controller, animated: true)
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

  func viewControllerDidRequestHistoryUpdate(_ viewController: TransactionHistoryViewController) {
    serialQueueManager.enqueueOptionalIncrementalSync()
  }

  func viewControllerDidDisplayTransactions(_ viewController: TransactionHistoryViewController) {
    badgeManager.setTransactionsDidDisplay()
  }

  func viewControllerDidTapScan(_ viewController: UIViewController, converter: CurrencyConverter) {
    analyticsManager.track(event: .scanQRButtonPressed, with: nil)
    permissionManager.requestPermission(for: .camera) { [weak self] status in
      switch status {
      case .authorized:
        self?.showScanViewController(fallbackBTCAmount: converter.btcAmount, primaryCurrency: converter.fromCurrency)
      default:
        break
      }
    }
  }

  func viewControllerDidTapReceivePayment(_ viewController: UIViewController, converter: CurrencyConverter) {
    if let requestViewController = createRequestPayViewController(converter: converter) {
      analyticsManager.track(event: .requestButtonPressed, with: nil)
      viewController.present(requestViewController, animated: true, completion: nil)
    }
  }

  func viewControllerDidTapSendPayment(_ viewController: UIViewController, converter: CurrencyConverter) {
    analyticsManager.track(event: .payButtonWasPressed, with: nil)

    let swappableVM = CurrencySwappableEditAmountViewModel(exchangeRates: self.currencyController.exchangeRates,
                                                           primaryAmount: converter.fromAmount,
                                                           currencyPair: self.currencyController.currencyPair)
    let sendPaymentVM = SendPaymentViewModel(editAmountViewModel: swappableVM)
    let sendPaymentViewController = SendPaymentViewController.newInstance(delegate: self, viewModel: sendPaymentVM)
    sendPaymentViewController.alertManager = self.alertManager
    navigationController.present(sendPaymentViewController, animated: true)
  }

  func viewControllerShouldAdjustForBottomSafeArea(_ viewController: UIViewController) -> Bool {
    return UIApplication.shared.delegate?.window??.safeAreaInsets.bottom ?? 0 == 0
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

  func viewControllerWillShowTransactionDetails(_ viewController: UIViewController) {
    CKNotificationCenter.publish(key: .willShowTransactionHistoryDetails)
  }

  func viewController(_ viewController: TransactionHistoryViewController, didSelectItemAtIndexPath indexPath: IndexPath) {
    let controller = TransactionHistoryDetailsViewController.newInstance(withDelegate: self,
                                                                         collectionViewDelegate: viewController,
                                                                         fetchedResultsController: viewController.frc,
                                                                         viewModelForIndexPath: { path in viewController.detailViewModel(at: path) },
                                                                         urlOpener: self)
    navigationController.present(controller, animated: true, completion: nil)
  }

  func viewControllerDidDismissTransactionDetails(_ viewController: UIViewController) {
    viewController.dismiss(animated: true, completion: nil)
    CKNotificationCenter.publish(key: .didDismissTransactionHistoryDetails)
  }
}
