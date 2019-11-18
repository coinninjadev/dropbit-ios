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
    let context = persistenceManager.viewContext
    guard let wmgr = walletManager,
      let btcAddress = wmgr.createAddressDataSource()
        .nextAvailableReceiveAddress(forServerPool: false, indicesToSkip: [], in: context)?
        .address else { return }
    let controller = GetBitcoinViewController.newInstance(delegate: self,
                                                          viewModels: getBitcoinDataSource(),
                                                          bitcoinAddress: btcAddress)
    navigationController.pushViewController(controller, animated: true)
  }

  private func getBitcoinDataSource() -> [BuyMerchantResponse] {
    var wyreAttributes: [BuyMerchantAttribute] = [], coinNinjaAttributes: [BuyMerchantAttribute] = []

    wyreAttributes.append(BuyMerchantAttribute(type: .positive,
                                               description: "Buy Bitcoin using Apple Pay"))
    wyreAttributes.append(BuyMerchantAttribute(type: .positive,
                                               description: "Takes less than 30 seconds"))
    wyreAttributes.append(BuyMerchantAttribute(type: .negative,
                                               description: "$500 daily limit"))
    var attribute = BuyMerchantAttribute(type: .negative,
                                         description: "Location restrictions may apply")
    attribute.link = "https://support.sendwyre.com/en/articles/1863574-geographic-restrictions"
    wyreAttributes.append(attribute)

    let wyre = BuyMerchantResponse(image: UIImage(imageLiteralResourceName: "wyreLogo"),
                                   tooltipUrl: "https://dropbit.app/tooltips/wyre",
                                   attributes: wyreAttributes,
                                   actionType: BuyMerchantBuyType.device.rawValue,
                                   actionUrl: "")

    coinNinjaAttributes.append(BuyMerchantAttribute(type: .positive,
                                               description: "Can use cash to buy"))
    coinNinjaAttributes.append(BuyMerchantAttribute(type: .positive,
                                               description: "Can sell Bitcoin for cash"))
    coinNinjaAttributes.append(BuyMerchantAttribute(type: .negative,
                                               description: "May limit based on verification"))
    coinNinjaAttributes.append(BuyMerchantAttribute(type: .negative,
                                               description: "High fees"))

    let coinNinja = BuyMerchantResponse(image: UIImage(imageLiteralResourceName: "coinNinjaLogo"),
                                        tooltipUrl: nil,
                                        attributes: coinNinjaAttributes,
                                        actionType: BuyMerchantBuyType.atm.rawValue,
                                        actionUrl: "")

    return [wyre, coinNinja]
  }

  func viewControllerDidTapSpendBitcoin(_ viewController: UIViewController) {
    analyticsManager.track(event: .spendBitcoinButtonPressed, with: nil)
    let controller = SpendBitcoinViewController.newInstance(delegate: self)
    navigationController.pushViewController(controller, animated: true)
  }

  func viewControllerAttemptedToRefreshTransactions(_ viewController: UIViewController) {
    serialQueueManager.enqueueOptionalIncrementalSync()
  }

  func viewControllerShouldSeeTransactionDetails(for viewModel: TransactionDetailPopoverDisplayable) {
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
    if viewController.viewModel.walletTransactionType == .lightning {
      analyticsManager.track(event: .lightningTransactionDetailsPressed, with: nil)
    }

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
