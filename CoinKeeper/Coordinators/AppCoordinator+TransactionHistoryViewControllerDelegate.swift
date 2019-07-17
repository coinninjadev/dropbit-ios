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

  func viewController(_ viewController: TransactionHistoryViewController, didCancelInvitationWithID invitationID: String, at indexPath: IndexPath) {

    let neverMindAction = AlertActionConfiguration(title: "Never mind", style: .cancel, action: nil)
    let cancelInvitationAction = AlertActionConfiguration(title: "Cancel DropBit", style: .default, action: { [weak self] in
      guard let strongSelf = self,
        let walletWorker = strongSelf.workerFactory.createWalletAddressDataWorker(delegate: strongSelf)
        else { return }
      let context = strongSelf.persistenceManager.createBackgroundContext()
      context.performAndWait {
        walletWorker.cancelInvitation(withID: invitationID, in: context)
          .done(in: context) {
            context.performAndWait {
              try? context.save()
            }

            strongSelf.analyticsManager.track(event: .cancelDropbitPressed, with: nil)

            DispatchQueue.main.async {
              // Manual reloading is necessary because the frc will not automatically reload
              // since the status change is made to the related invitation and not the transaction.
              viewController.reloadTransactions(atIndexPaths: [indexPath])
            }
          }
          .catch { error in
            strongSelf.alertManager.showError(message: "Failed to cancel invitation.\nError details: \(error.localizedDescription)", forDuration: 5.0)
        }
      }
    })

    let alert = alertManager.alert(withTitle: "Cancel DropBit",
                                   description: "Are you sure you want to cancel this DropBit invitation?",
                                   image: nil,
                                   style: .alert,
                                   actionConfigs: [neverMindAction, cancelInvitationAction])
    viewController.present(alert, animated: true, completion: nil)
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

    let currencies = SwappableCurrencies(primary: converter.fromCurrency, secondary: converter.toCurrency, fiat: converter.fiatCurrency)
    let swappableVM = CurrencySwappableEditAmountViewModel(exchangeRates: self.currencyController.exchangeRates,
                                                           primaryAmount: converter.fromAmount,
                                                           swappableCurrencies: currencies)
    let sendPaymentVM = SendPaymentViewModel(editAmountViewModel: swappableVM)
    let sendPaymentViewController = SendPaymentViewController.newInstance(delegate: self, viewModel: sendPaymentVM)
    sendPaymentViewController.alertManager = self.alertManager
    navigationController.present(sendPaymentViewController, animated: true)
  }

}
