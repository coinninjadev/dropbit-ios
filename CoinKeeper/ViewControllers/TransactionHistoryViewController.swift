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
  BadgeUpdateDelegate {
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

  @IBOutlet var summaryCollectionView: TransactionHistorySummaryCollectionView!
  @IBOutlet var transactionHistoryNoBalanceView: TransactionHistoryNoBalanceView!
  @IBOutlet var transactionHistoryWithBalanceView: TransactionHistoryWithBalanceView!
  @IBOutlet var refreshView: TransactionHistoryRefreshView!
  @IBOutlet var refreshViewTopConstraint: NSLayoutConstraint!
  @IBOutlet var footerView: UIView!
  @IBOutlet var gradientBlurView: UIView! {
    didSet {
      gradientBlurView.backgroundColor = .white
      gradientBlurView.fade(style: .top, percent: 1.0)
    }
  }

  var isCollectionViewFullScreen: Bool = false {
    willSet {
      footerView.isHidden = !newValue
      gradientBlurView.isHidden = !newValue
    }
  }

  var currencyValueManager: CurrencyValueDataSourceType?
  var rateManager: ExchangeRateManager = ExchangeRateManager()

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

  weak var urlOpener: URLOpener?

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

  lazy var frc: NSFetchedResultsController<CKMTransaction> = {
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.sortDescriptors = CKMTransaction.transactionHistorySortDescriptors
    fetchRequest.fetchBatchSize = 25
    let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                managedObjectContext: context,
                                                sectionNameKeyPath: nil,
                                                cacheName: nil) // avoid caching unless there is real need as it is often the source of bugs
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

    self.view.backgroundColor = .clear

    view.layoutIfNeeded()

    coordinationDelegate?.viewControllerDidRequestBadgeUpdate(self)

    setupCollectionViews()
    self.frc.delegate = self
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
    let transaction = frc.object(at: indexPath)
    return TransactionHistoryDetailCellViewModel(
      transaction: transaction,
      rates: rateManager.exchangeRates,
      primaryCurrency: preferredCurrency(),
      deviceCountryCode: deviceCountryCode
    )
  }

  func summaryViewModel(for transaction: CKMTransaction) -> TransactionHistorySummaryCellViewModel {
    return TransactionHistorySummaryCellViewModel(
      transaction: transaction,
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

    summaryCollectionView.delegate = self
    summaryCollectionView.dataSource = self
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
    return shouldShowNoBalanceView || shouldShowWithBalanceView
  }

  func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool {
    return shouldShowNoBalanceView || shouldShowWithBalanceView
  }

  func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView!) -> Bool {
    return true
  }

  func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {
    if shouldShowNoBalanceView {
      transactionHistoryNoBalanceView.isHidden = false
      return transactionHistoryNoBalanceView
    }
    if shouldShowWithBalanceView {
      transactionHistoryWithBalanceView.isHidden = false
      return transactionHistoryWithBalanceView
    }
    return nil
  }

  private var shouldShowNoBalanceView: Bool {
    return (frc.fetchedObjects?.count ?? 0) == 0
  }

  private var shouldShowWithBalanceView: Bool {
    return (frc.fetchedObjects?.count ?? 0) == 1
  }
}
