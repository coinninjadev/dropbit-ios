//
//  TransactionHistoryViewController.swift
//  CoinKeeper
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
  BadgeUpdateDelegate & URLOpener & LightningTransactionHistoryEmptyViewDelegate {
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

protocol TransactionHistorySummaryCollectionViewDelegate: class {
  func collectionViewDidProvideHitTestPoint(_ point: CGPoint, in view: UIView) -> UIView?
  func collectionViewDidCoverWalletBalance()
  func collectionViewDidUncoverWalletBalance()
}

class TransactionHistorySummaryCollectionView: UICollectionView {

  let topInset: CGFloat = 140
  let topConstraintConstant: CGFloat = 62
  weak var historyDelegate: TransactionHistorySummaryCollectionViewDelegate?

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard let hitView = super.hitTest(point, with: event) else { return nil }

    return hitView is UICollectionView ? historyDelegate?.collectionViewDidProvideHitTestPoint(point, in: hitView) : hitView
  }

}

class TransactionHistoryViewController: BaseViewController, StoryboardInitializable {

  enum WalletTransactionType {
    case onChain
    case lightning
  }

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

  static func newInstance(withDelegate delegate: TransactionHistoryViewControllerDelegate, context dbContext: NSManagedObjectContext,
                          type: WalletTransactionType = .onChain) -> TransactionHistoryViewController {
    let txHistory = TransactionHistoryViewController.makeFromStoryboard()
    txHistory.generalCoordinationDelegate = delegate
    txHistory.context = dbContext
    txHistory.transactionType = type

    return txHistory
  }

  var isCollectionViewFullScreen: Bool = false {
    willSet {
      footerView.isHidden = !newValue
      gradientBlurView.isHidden = !newValue
    }
  }

  var currencyValueManager: CurrencyValueDataSourceType?
  var rateManager: ExchangeRateManager = ExchangeRateManager()
  var transactionType: WalletTransactionType = .onChain

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .transactionHistory(.page)),
      (transactionHistoryNoBalanceView.learnAboutBitcoinButton, .transactionHistory(.tutorialButton))
    ]
  }

  lazy var phoneFormatter: CKPhoneNumberFormatter = {
    return CKPhoneNumberFormatter(format: .national)
  }()

  var deviceCountryCode: Int?

  override var generalCoordinationDelegate: AnyObject? {
    didSet {
      if let persistedCountryCode = coordinationDelegate?.deviceCountryCode() {
        self.deviceCountryCode = persistedCountryCode
      } else if let regionCode = Locale.current.regionCode,
        let countryCode = phoneNumberKit.countryCode(for: regionCode) {
        self.deviceCountryCode = Int(countryCode)
      }
    }
  }

  var coordinationDelegate: TransactionHistoryViewControllerDelegate? {
    return generalCoordinationDelegate as? TransactionHistoryViewControllerDelegate
  }

  unowned var context: NSManagedObjectContext!
  var isLightning: Bool = false

  lazy var onChainDDS = TransactionHistoryViewControllerOnChainDDS(viewController: self)
  lazy var onChainFetchResultsController: NSFetchedResultsController<CKMTransaction> = {
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.sortDescriptors = CKMTransaction.transactionHistorySortDescriptors
    fetchRequest.fetchBatchSize = 25
    let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                managedObjectContext: context,
                                                sectionNameKeyPath: nil,
                                                cacheName: nil) // avoid caching unless there is real need as it is often the source of bugs
    controller.delegate = self
    try? controller.performFetch()
    return controller
  }()

  lazy var lightningDDS = TransactionHistoryViewControllerLightningDDS(viewController: self)
  lazy var lightningFetchResultsController: NSFetchedResultsController<CKMWalletEntry> = {
    let fetchRequest: NSFetchRequest<CKMWalletEntry> = CKMWalletEntry.fetchRequest()
    fetchRequest.sortDescriptors = CKMWalletEntry.transactionHistorySortDescriptors
    fetchRequest.fetchBatchSize = 25
    let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                managedObjectContext: context,
                                                sectionNameKeyPath: nil,
                                                cacheName: nil) // avoid caching unless there is real need as it is often the source of bugs
    controller.delegate = self
    try? controller.performFetch()
    return controller
  }()

  func preferredCurrency() -> CurrencyCode {
    guard let selected = coordinationDelegate?.currencyController.selectedCurrency else { return .USD }
    switch selected {
    case .BTC:
      return .BTC
    case .fiat:
      return .USD
    }
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

  private func resetCollectionView() {
    summaryCollectionView.contentOffset = CGPoint(x: 0, y: -summaryCollectionView.topInset)
    summaryCollectionView.delegate?.scrollViewDidScroll?(summaryCollectionView)
  }

  func detailViewModel(at indexPath: IndexPath) -> TransactionHistoryDetailCellViewModel {
    let viewModel: TransactionHistoryDetailCellViewModel
    switch transactionType {
    case .onChain:
      let transaction = onChainFetchResultsController.object(at: indexPath)
      viewModel = TransactionHistoryDetailCellViewModel(
        transaction: transaction,
        rates: rateManager.exchangeRates,
        primaryCurrency: preferredCurrency(),
        deviceCountryCode: deviceCountryCode
      )
    case .lightning:
      let walletEntry = lightningFetchResultsController.object(at: indexPath)
      viewModel = TransactionHistoryDetailCellViewModel(
        walletEntry: walletEntry,
        rates: rateManager.exchangeRates,
        primaryCurrency: preferredCurrency(),
        deviceCountryCode: deviceCountryCode
      )
    }

    return viewModel
  }

  func summaryViewModel(for transaction: CKMTransaction) -> TransactionHistorySummaryCellViewModel {
    return TransactionHistorySummaryCellViewModel(
      transaction: transaction,
      rates: rateManager.exchangeRates,
      primaryCurrency: preferredCurrency(),
      deviceCountryCode: deviceCountryCode
    )
  }

  func summaryViewModel(for walletEntry: CKMWalletEntry) -> TransactionHistorySummaryCellViewModel {
    return TransactionHistorySummaryCellViewModel(
      walletEntry: walletEntry,
      rates: rateManager.exchangeRates,
      primaryCurrency: preferredCurrency(),
      deviceCountryCode: deviceCountryCode
    )
  }

  private func setupCollectionViews() {
    summaryCollectionView.registerNib(cellType: TransactionHistorySummaryCell.self)
    summaryCollectionView.showsVerticalScrollIndicator = false
    summaryCollectionView.alwaysBounceVertical = true
    summaryCollectionView.contentInset = UIEdgeInsets(top: summaryCollectionView.topInset, left: 0, bottom: 0, right: 0)

    switch transactionType {
    case .onChain:
      summaryCollectionView.delegate = onChainDDS
      summaryCollectionView.dataSource = onChainDDS
    case .lightning:
      summaryCollectionView.delegate = lightningDDS
      summaryCollectionView.dataSource = lightningDDS
    }

    summaryCollectionView.backgroundColor = .clear

    summaryCollectionView.collectionViewLayout = summaryCollectionViewLayout()

    reloadCollectionViews()

    summaryCollectionView.emptyDataSetSource = self
    summaryCollectionView.emptyDataSetDelegate = self
  }

  fileprivate func reloadCollectionViews() {
    summaryCollectionView.reloadData()
    coordinationDelegate?.viewControllerSummariesDidReload(self, indexPathsIfNotAll: nil)
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

extension TransactionHistoryViewController: NSFetchedResultsControllerDelegate {
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    reloadCollectionViews()
  }

  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    transactionHistoryWithBalanceView.isHidden = true
    transactionHistoryNoBalanceView.isHidden = true
    lightningTransactionHistoryEmptyBalanceView.isHidden = true
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

extension TransactionHistoryViewController: ExchangeRateUpdateable {

  func didUpdateExchangeRateManager(_ exchangeRateManager: ExchangeRateManager) {
    rateManager.exchangeRates = exchangeRateManager.exchangeRates
    coordinationDelegate?.currencyController.exchangeRates = exchangeRateManager.exchangeRates
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
    var view: UIView?

    if shouldShowNoBalanceView {
      transactionHistoryNoBalanceView.isHidden = false
      view = transactionHistoryNoBalanceView
    } else if shouldShowWithBalanceView {
      transactionHistoryWithBalanceView.isHidden = false
      view = transactionHistoryWithBalanceView
    } else if shouldShowLightningEmptyView {
      lightningTransactionHistoryEmptyBalanceView.isHidden = false
      view = lightningTransactionHistoryEmptyBalanceView
    }

    return view
  }

  func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
    return 0
  }

  private var shouldShowLightningEmptyView: Bool {
    return (lightningFetchResultsController.fetchedObjects?.count ?? 0) == 0 && transactionType == .lightning
  }

  private var shouldShowNoBalanceView: Bool {
    return (onChainFetchResultsController.fetchedObjects?.count ?? 0) == 0 && transactionType == .onChain
  }

  private var shouldShowWithBalanceView: Bool {
    return (onChainFetchResultsController.fetchedObjects?.count ?? 0) == 1 && transactionType == .onChain
  }
}

extension TransactionHistoryViewController {

  func summaryCollectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.scrollDirection = .vertical
    return layout
  }

}

extension TransactionHistoryViewController: UIScrollViewDelegate {

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let topOfWalletBalanceOffset: CGFloat = -60, middleOfWalletBalanceOffset: CGFloat = -100
    let collectionViewFullScreenOffset = scrollView.contentOffset.y < middleOfWalletBalanceOffset
    let collectionViewPartialScreenOffset = scrollView.contentOffset.y > topOfWalletBalanceOffset
    guard collectionViewFullScreenOffset || collectionViewPartialScreenOffset else { return }

    if collectionViewPartialScreenOffset {
      summaryCollectionView.historyDelegate?.collectionViewDidCoverWalletBalance()
      isCollectionViewFullScreen = false
    } else {
      summaryCollectionView.historyDelegate?.collectionViewDidUncoverWalletBalance()
      isCollectionViewFullScreen = true
    }

    let offset = abs(scrollView.contentOffset.y)
    refreshViewTopConstraint.constant = offset - refreshView.frame.size.height
    refreshView.animateLogo(to: scrollView.contentOffset.y)
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    refreshView.reset()
    refreshViewTopConstraint.constant = 0
  }

  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    refreshView.fireRefreshAnimationIfNecessary()

    if refreshView.shouldQueueRefresh {
      coordinationDelegate?.viewControllerAttemptedToRefreshTransactions(self)
    }
  }
}
