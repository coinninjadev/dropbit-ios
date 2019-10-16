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
  BadgeUpdateDelegate & URLOpener & LightningReloadDelegate & CurrencyValueDataSourceType &
  TweetDelegate {
  func viewControllerDidRequestHistoryUpdate(_ viewController: TransactionHistoryViewController)
  func viewControllerDidDisplayTransactions(_ viewController: TransactionHistoryViewController)
  func viewControllerAttemptedToRefreshTransactions(_ viewController: UIViewController)

  func viewControllerDidRequestTutorial(_ viewController: UIViewController)
  func viewControllerDidTapGetBitcoin(_ viewController: UIViewController)
  func viewControllerDidTapSpendBitcoin(_ viewController: UIViewController)

  var currencyController: CurrencyController { get }
  func viewControllerSummariesDidReload(_ viewController: TransactionHistoryViewController, indexPathsIfNotAll paths: [IndexPath]?)
  func viewController(_ viewController: TransactionHistoryViewController, didSelectItemAtIndexPath indexPath: IndexPath)
  func viewControllerDidDismissTransactionDetails(_ viewController: UIViewController)

  /// Return nil to hide header
  func summaryHeaderType(for viewController: UIViewController) -> SummaryHeaderType?
  func viewControllerDidSelectSummaryHeader(_ viewController: UIViewController)
}

class TransactionHistoryViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var emptyStateBackgroundView: UIView!
  @IBOutlet var emptyStateBackgroundTopConstraint: NSLayoutConstraint!
  @IBOutlet var summaryCollectionView: TransactionHistorySummaryCollectionView!
  @IBOutlet var transactionHistoryNoBalanceView: TransactionHistoryNoBalanceView!
  @IBOutlet var transactionHistoryWithBalanceView: TransactionHistoryWithBalanceView!
  @IBOutlet var lockedLightningView: LockedLightningView!
  @IBOutlet var lightningUnavailableView: LightningUnavailableView!
  @IBOutlet var lightningTransactionHistoryEmptyBalanceView: LightningTransactionHistoryEmptyView!
  @IBOutlet var refreshView: TransactionHistoryRefreshView!
  @IBOutlet var refreshViewTopConstraint: NSLayoutConstraint!
  @IBOutlet var footerView: UIView!
  @IBOutlet var gradientBlurView: UIView!

  weak var delegate: TransactionHistoryViewControllerDelegate!

  var viewModel: TransactionHistoryViewModel!
  var selectedCurrency: SelectedCurrency = .fiat

  static func newInstance(withDelegate delegate: TransactionHistoryViewControllerDelegate,
                          walletTxType: WalletTransactionType,
                          dataSource: TransactionHistoryDataSourceType) -> TransactionHistoryViewController {
    let viewController = TransactionHistoryViewController.makeFromStoryboard()
    viewController.delegate = delegate
    viewController.viewModel = TransactionHistoryViewModel(delegate: viewController,
                                                           detailsDelegate: nil,
                                                           currencyManager: delegate,
                                                           deviceCountryCode: delegate.deviceCountryCode(),
                                                           transactionType: walletTxType,
                                                           dataSource: dataSource)
    viewController.viewModel.dataSource.delegate = viewController
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

  override func viewDidLoad() {
    super.viewDidLoad()

    transactionHistoryNoBalanceView.delegate = self
    transactionHistoryWithBalanceView.delegate = self
    lightningTransactionHistoryEmptyBalanceView.delegate = delegate
    emptyStateBackgroundView.isHidden = false
    emptyStateBackgroundView.backgroundColor = .whiteBackground
    configureOnChainEmptyStateButtons()
    if viewModel.walletTransactionType == .onChain {
      lockedLightningView.isHidden = true
      lightningUnavailableView.isHidden = true
    }

    view.backgroundColor = .clear
    emptyStateBackgroundView.applyCornerRadius(30, toCorners: .top)
    delegate.viewControllerDidRequestBadgeUpdate(self)

    CKNotificationCenter.subscribe(self, key: .didUpdateWordsBackedUp, selector: #selector(didUpdateWordsBackedUp))

    setupCollectionViews()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: true)
    resetCollectionView()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    configureGradientBlurView() //the CAGradientLayer doesn't use autolayout, so need to keep its bounds updated here
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    // In case new transactions came it while this view was open, this will hide the badge
    delegate.viewControllerDidDisplayTransactions(self)
  }

  override func lock() {
    if viewModel.walletTransactionType == .lightning {
      lockedLightningView.isHidden = false
      lightningUnavailableView.isHidden = true
    }
  }

  override func makeUnavailable() {
    if viewModel.walletTransactionType == .lightning {
      lockedLightningView.isHidden = true
      lightningUnavailableView.isHidden = false
    }
  }

  override func unlock() {
    lockedLightningView.isHidden = true
    lightningUnavailableView.isHidden = true
  }

  internal func reloadTransactions(atIndexPaths paths: [IndexPath]) {
    summaryCollectionView.reloadItems(at: paths)
    delegate.viewControllerSummariesDidReload(self, indexPathsIfNotAll: paths)
  }

}

extension TransactionHistoryViewController { // Layout

  func showDetailCollectionView(_ shouldShow: Bool, indexPath: IndexPath, animated: Bool) {
    if shouldShow {
      delegate.viewController(self, didSelectItemAtIndexPath: indexPath)
    } else {
      delegate.viewControllerDidDismissTransactionDetails(self)
    }
  }

  /// 20 for most devices, 44 on iPhone X
  private var statusBarHeight: CGFloat {
    return UIApplication.shared.statusBarFrame.height
  }

  func configureGradientBlurView() {
    gradientBlurView.backgroundColor = .white
    gradientBlurView.fade(style: .top, percent: 1.0)
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

  @objc func didUpdateWordsBackedUp() {
    transactionDataSourceDidChange()
  }

}

extension TransactionHistoryViewController: NoTransactionsViewDelegate {
  func noTransactionsViewDidSelectGetBitcoin(_ view: TransactionHistoryEmptyView) {
    delegate.viewControllerDidTapGetBitcoin(self)
  }

  func noTransactionsViewDidSelectSpendBitcoin(_ view: TransactionHistoryEmptyView) {
    delegate.viewControllerDidTapSpendBitcoin(self)
  }

  func noTransactionsViewDidSelectLearnAboutBitcoin(_ view: TransactionHistoryEmptyView) {
    delegate.viewControllerDidRequestTutorial(self)
  }
}

extension TransactionHistoryViewController: SelectedCurrencyUpdatable {
  func updateSelectedCurrency(to selectedCurrency: SelectedCurrency) {
    let summaryIndexSet = IndexSet(integersIn: (0..<summaryCollectionView.numberOfSections))
    summaryCollectionView.reloadSections(summaryIndexSet)
    delegate.viewControllerSummariesDidReload(self, indexPathsIfNotAll: nil)
  }
}

extension TransactionHistoryViewController: TransactionHistoryViewModelDelegate {

  var currencyController: CurrencyController {
    return delegate.currencyController
  }

  func viewModelDidUpdateExchangeRates() {
    reloadCollectionViews()
  }

  func summaryHeaderType() -> SummaryHeaderType? {
    return delegate.summaryHeaderType(for: self)
  }

  func didTapSummaryHeader(_ header: TransactionHistorySummaryHeader) {
    self.delegate.viewControllerDidSelectSummaryHeader(self)
  }

}

extension TransactionHistoryViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {

  func emptyDataSetShouldBeForced(toDisplay scrollView: UIScrollView!) -> Bool {
    return viewModel.shouldShowEmptyDataSet
  }

  func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
    let shouldDisplay = viewModel.shouldShowEmptyDataSet
    let offset = verticalOffset(forEmptyDataSet: scrollView)
    emptyStateBackgroundTopConstraint.constant = SummaryCollectionView.topInset + offset
    emptyStateBackgroundView.isHidden = !shouldDisplay
    return shouldDisplay
  }

  func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView!) -> Bool {
    return true
  }

  func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {
    let dataSetType = viewModel.emptyDataSetToDisplay()
    switch dataSetType {
    case .noBalance:
      transactionHistoryNoBalanceView.isHidden = false
      return transactionHistoryNoBalanceView
    case .balance:
      transactionHistoryWithBalanceView.isHidden = false
      return transactionHistoryWithBalanceView
    case .lightning:
      lightningTransactionHistoryEmptyBalanceView.isHidden = false
      return lightningTransactionHistoryEmptyBalanceView
    case .none:
      return nil
    }
  }

  func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
    let headerIsShown = delegate.summaryHeaderType(for: self) != nil
    let headerHeight = headerIsShown ? self.viewModel.warningHeaderHeight : 0
    let dataSetType = viewModel.emptyDataSetToDisplay()
    switch dataSetType {
    case .balance:
      let contentOffset = (headerHeight + SummaryCollectionView.cellHeight) / 2
      let paddedOffset = (contentOffset > 0) ? (contentOffset + 20) : 0
      return paddedOffset

    default:
      return 0
    }
  }

  ///These buttons apply a default style during awakeFromNib, which is triggered after these outlets
  ///didSet, so need to set the button styles later in the view lifecycle.
  func configureOnChainEmptyStateButtons() {
    let views = [transactionHistoryNoBalanceView, transactionHistoryWithBalanceView]
    for view in views {
      view?.getBitcoinButton?.style = .green
      view?.learnAboutBitcoinButton?.style = .darkBlue
    }

    transactionHistoryWithBalanceView?.spendBitcoinButton?.style = .orange
  }
}
