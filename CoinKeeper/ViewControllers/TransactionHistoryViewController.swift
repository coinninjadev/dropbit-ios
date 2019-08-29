//
//  TransactionHistoryViewController.swift
//  DropBit
//
//  Created by Ben Winters on 4/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import UIKit
import CNBitcoinKit
import Gifu
import PromiseKit
import DZNEmptyDataSet

protocol TransactionHistoryViewControllerDelegate: DeviceCountryCodeProvider &
  BadgeUpdateDelegate & URLOpener & LightningTransactionHistoryEmptyViewDelegate & CurrencyValueDataSourceType {
  func viewControllerDidRequestHistoryUpdate(_ viewController: TransactionHistoryViewController)
  func viewControllerDidDisplayTransactions(_ viewController: TransactionHistoryViewController)
  func viewControllerAttemptedToRefreshTransactions(_ viewController: UIViewController)

  func viewControllerDidRequestTutorial(_ viewController: UIViewController)
  func viewControllerDidTapGetBitcoin(_ viewController: UIViewController)
  func viewControllerDidTapSpendBitcoin(_ viewController: UIViewController)

  var currencyController: CurrencyController { get }
  func viewControllerSummariesDidReload(_ viewController: TransactionHistoryViewController, indexPathsIfNotAll paths: [IndexPath]?)
  func viewControllerWillShowTransactionDetails(_ viewController: UIViewController)
  func viewController(_ viewController: TransactionHistoryViewController, didSelectItemAtIndexPath indexPath: IndexPath)
  func viewControllerDidDismissTransactionDetails(_ viewController: UIViewController)
}

class TransactionHistoryViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var emptyStateBackgroundView: UIView!
  @IBOutlet var summaryCollectionView: TransactionHistorySummaryCollectionView!
  @IBOutlet var transactionHistoryNoBalanceView: TransactionHistoryNoBalanceView!
  @IBOutlet var transactionHistoryWithBalanceView: TransactionHistoryWithBalanceView!
  @IBOutlet var lightningTransactionHistoryEmptyBalanceView: LightningTransactionHistoryEmptyView!
  @IBOutlet var refreshView: TransactionHistoryRefreshView!
  @IBOutlet var refreshViewTopConstraint: NSLayoutConstraint!
  @IBOutlet var footerView: UIView!
  @IBOutlet var gradientBlurView: UIView! {
    didSet {
      gradientBlurView.backgroundColor = .white
      gradientBlurView.fade(style: .top, percent: 1.0)
    }
  }

  var viewModel: TransactionHistoryViewModel!
  var selectedCurrency: SelectedCurrency = .fiat
  var lightningLoadAddress: String?

  static func newInstance(withDelegate delegate: TransactionHistoryViewControllerDelegate,
                          walletTxType: WalletTransactionType,
                          dataSource: TransactionHistoryDataSourceType) -> TransactionHistoryViewController {
    let viewController = TransactionHistoryViewController.makeFromStoryboard()
    viewController.generalCoordinationDelegate = delegate
    dataSource.delegate = viewController
    viewController.viewModel = TransactionHistoryViewModel(delegate: viewController,
                                                           currencyManager: delegate,
                                                           deviceCountryCode: delegate.deviceCountryCode(),
                                                           transactionType: walletTxType,
                                                           dataSource: dataSource)
    return viewController
  }

  var isCollectionViewFullScreen: Bool = false {
    willSet {
      footerView.isHidden = !newValue
      gradientBlurView.isHidden = !newValue
    }
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .transactionHistory(.page)),
      (transactionHistoryNoBalanceView.learnAboutBitcoinButton, .transactionHistory(.tutorialButton))
    ]
  }

  var coordinationDelegate: TransactionHistoryViewControllerDelegate! {
    return generalCoordinationDelegate as? TransactionHistoryViewControllerDelegate
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    transactionHistoryNoBalanceView.delegate = self
    transactionHistoryWithBalanceView.delegate = self
    lightningTransactionHistoryEmptyBalanceView.delegate = coordinationDelegate
    emptyStateBackgroundView.isHidden = true

    view.backgroundColor = .clear
    emptyStateBackgroundView.applyCornerRadius(30)
    coordinationDelegate?.viewControllerDidRequestBadgeUpdate(self)

    setupCollectionViews()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: true)
    resetCollectionView()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    // In case new transactions came it while this view was open, this will hide the badge
    coordinationDelegate?.viewControllerDidDisplayTransactions(self)
  }

  internal func reloadTransactions(atIndexPaths paths: [IndexPath]) {
    summaryCollectionView.reloadItems(at: paths)
    coordinationDelegate?.viewControllerSummariesDidReload(self, indexPathsIfNotAll: paths)
  }

}

extension TransactionHistoryViewController { // Layout

  func showDetailCollectionView(_ shouldShow: Bool, indexPath: IndexPath, animated: Bool) {
    if shouldShow {
      coordinationDelegate?.viewControllerWillShowTransactionDetails(self)
      coordinationDelegate?.viewController(self, didSelectItemAtIndexPath: indexPath)
    } else {
      coordinationDelegate?.viewControllerDidDismissTransactionDetails(self)
    }
  }

  /// 20 for most devices, 44 on iPhone X
  private var statusBarHeight: CGFloat {
    return UIApplication.shared.statusBarFrame.height
  }

}

extension TransactionHistoryViewController: TransactionHistoryDataSourceDelegate {
  func transactionDataSourceWillChange() {
    transactionHistoryWithBalanceView.isHidden = true
    transactionHistoryNoBalanceView.isHidden = true
    lightningTransactionHistoryEmptyBalanceView.isHidden = true
  }

  func transactionDataSourceDidChange() {
    reloadCollectionViews()
  }
}

extension TransactionHistoryViewController: NoTransactionsViewDelegate {
  func noTransactionsViewDidSelectGetBitcoin(_ view: TransactionHistoryEmptyView) {
    coordinationDelegate?.viewControllerDidTapGetBitcoin(self)
  }

  func noTransactionsViewDidSelectSpendBitcoin(_ view: TransactionHistoryEmptyView) {
    coordinationDelegate?.viewControllerDidTapSpendBitcoin(self)
  }

  func noTransactionsViewDidSelectLearnAboutBitcoin(_ view: TransactionHistoryEmptyView) {
    coordinationDelegate?.viewControllerDidRequestTutorial(self)
  }
}

extension TransactionHistoryViewController: SelectedCurrencyUpdatable {
  func updateSelectedCurrency(to selectedCurrency: SelectedCurrency) {
    let summaryIndexSet = IndexSet(integersIn: (0..<summaryCollectionView.numberOfSections))
    summaryCollectionView.reloadSections(summaryIndexSet)
    coordinationDelegate?.viewControllerSummariesDidReload(self, indexPathsIfNotAll: nil)
  }
}

extension TransactionHistoryViewController: TransactionHistoryViewModelDelegate {

  var currencyController: CurrencyController {
    return coordinationDelegate.currencyController
  }

  func viewModelDidUpdateExchangeRates() {
    reloadCollectionViews()
  }

}

extension TransactionHistoryViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
  func emptyDataSetShouldBeForced(toDisplay scrollView: UIScrollView!) -> Bool {
    return shouldShowNoBalanceView || shouldShowWithBalanceView || shouldShowLightningEmptyView
  }

  func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
    let shouldDisplay = shouldShowNoBalanceView || shouldShowWithBalanceView || shouldShowLightningEmptyView
    emptyStateBackgroundView.isHidden = !shouldDisplay
    return shouldDisplay
  }

  func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView!) -> Bool {
    return true
  }

  func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {
    if shouldShowNoBalanceView {
      transactionHistoryNoBalanceView.isHidden = false
      return transactionHistoryNoBalanceView
    } else if shouldShowWithBalanceView {
      transactionHistoryWithBalanceView.isHidden = false
      return transactionHistoryWithBalanceView
    } else if shouldShowLightningEmptyView {
      lightningTransactionHistoryEmptyBalanceView.isHidden = false
      return lightningTransactionHistoryEmptyBalanceView
    } else {
      return nil
    }
  }

  func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
    return 0
  }

  private var shouldShowLightningEmptyView: Bool {
    return viewModel.dataSource.numberOfItems(inSection: 0) == 0 && viewModel.walletTransactionType == .lightning
  }

  private var shouldShowNoBalanceView: Bool {
    return viewModel.dataSource.numberOfItems(inSection: 0) == 0 && viewModel.walletTransactionType == .onChain
  }

  private var shouldShowWithBalanceView: Bool {
    return viewModel.dataSource.numberOfItems(inSection: 0) == 1 && viewModel.walletTransactionType == .onChain
  }
}
