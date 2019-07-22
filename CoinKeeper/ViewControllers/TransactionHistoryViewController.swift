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
  BadgeUpdateDelegate &
  TransactionShareable {
  func viewControllerShouldSeeTransactionDetails(for viewModel: TransactionHistoryDetailCellViewModel)
  func viewControllerDidRequestHistoryUpdate(_ viewController: TransactionHistoryViewController)
  func viewController(_ viewController: TransactionHistoryViewController, didCancelInvitationWithID invitationID: String, at indexPath: IndexPath)
  func viewControllerDidDisplayTransactions(_ viewController: TransactionHistoryViewController)
  func viewControllerAttemptedToRefreshTransactions(_ viewController: UIViewController)
  func viewControllerDidTapAddMemo(_ viewController: UIViewController, with completion: @escaping (String) -> Void)
  func viewControllerShouldUpdateTransaction(_ viewController: TransactionHistoryViewController,
                                             transaction: CKMTransaction) -> Promise<Void>

  func viewControllerDidTapScan(_ viewController: UIViewController, converter: CurrencyConverter)
  func viewControllerDidTapReceivePayment(_ viewController: UIViewController, converter: CurrencyConverter)
  func viewControllerDidTapSendPayment(_ viewController: UIViewController, converter: CurrencyConverter)

  func viewControllerDidRequestTutorial(_ viewController: UIViewController)
  func viewControllerDidTapGetBitcoin(_ viewController: UIViewController)
  func viewControllerDidTapSpendBitcoin(_ viewController: UIViewController)

  var currencyController: CurrencyController { get }
  func viewControllerShouldAdjustForBottomSafeArea(_ viewController: UIViewController) -> Bool
}

class TransactionHistoryViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var summaryCollectionView: UICollectionView!
  @IBOutlet var detailCollectionView: UICollectionView!
  @IBOutlet var detailCollectionViewTopConstraint: NSLayoutConstraint!
  @IBOutlet var detailCollectionViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet var transactionHistoryNoBalanceView: TransactionHistoryNoBalanceView!
  @IBOutlet var transactionHistoryWithBalanceView: TransactionHistoryWithBalanceView!
  @IBOutlet var collectionViews: [UICollectionView]!
  @IBOutlet var refreshView: TransactionHistoryRefreshView!
  @IBOutlet var refreshViewTopConstraint: NSLayoutConstraint!
  @IBOutlet var sendReceiveActionViewBottomConstraint: NSLayoutConstraint!
  @IBOutlet var sendReceiveActionView: SendReceiveActionView! {
    didSet {
      sendReceiveActionView.actionDelegate = self
    }
  }
  @IBOutlet var gradientBlurView: UIView! {
    didSet {
      gradientBlurView.backgroundColor = .lightGrayBackground
      gradientBlurView.fade(style: .top, percent: 1.0)
    }
  }

  var currencyValueManager: CurrencyValueDataSourceType?
  var rateManager: ExchangeRateManager = ExchangeRateManager()

  private enum CollectionViewType {
    case summary, detail
    static let all: [CollectionViewType] = [.summary, .detail]
  }

  private func collectionView(_ type: CollectionViewType) -> UICollectionView {
    switch type {
    case .summary:	return summaryCollectionView
    case .detail:	return detailCollectionView
    }
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .transactionHistory(.page)),
      (sendReceiveActionView.receiveButton, .transactionHistory(.receiveButton)),
      (sendReceiveActionView.sendButton, .transactionHistory(.sendButton)),
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

    self.view.backgroundColor = .lightGrayBackground

    let bottomOffsetIfNeeded: CGFloat = 20
    if let delegate = coordinationDelegate, delegate.viewControllerShouldAdjustForBottomSafeArea(self) {
      sendReceiveActionViewBottomConstraint.constant = bottomOffsetIfNeeded
    }

    view.layoutIfNeeded()
    let offset = CGFloat(80) //Offset for height of balance container + top constraint of container view in WalletOverviewViewController
    detailCollectionViewHeightConstraint.constant = self.view.frame.height - offset

    coordinationDelegate?.viewControllerDidRequestBadgeUpdate(self)

    setupCollectionViews()
    self.frc.delegate = self

    if #available(iOS 11.0, *) {
      self.detailCollectionView.contentInsetAdjustmentBehavior = .never
    }

    showDetailCollectionView(false, animated: false)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: true)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    // In case new transactions came it while this view was open, this will hide the badge
    coordinationDelegate?.viewControllerDidDisplayTransactions(self)
  }

  internal func reloadTransactions(atIndexPaths paths: [IndexPath]) {
    summaryCollectionView.reloadItems(at: paths)
    detailCollectionView.reloadItems(at: paths)
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
    detailCollectionView.registerNib(cellType: TransactionHistoryDetailInvalidCell.self)
    detailCollectionView.registerNib(cellType: TransactionHistoryDetailValidCell.self)
    summaryCollectionView.alwaysBounceVertical = true

    for cView in self.collectionViews {
      cView.delegate = self
      cView.dataSource = self
      cView.backgroundColor = .clear
    }

    summaryCollectionView.collectionViewLayout = summaryCollectionViewLayout()

    let hPadding: CGFloat = 8 // amount of space between cell edge and screen edge, to allow showing previous/next cell
    detailCollectionView.contentInset = UIEdgeInsets(top: 0, left: hPadding, bottom: 0, right: hPadding) // allow first and last cells to be centered
    detailCollectionView.isPagingEnabled = false
    detailCollectionView.collectionViewLayout = detailCollectionViewLayout(withHorizontalPadding: hPadding)

    collectionViews.forEach { $0.reloadData() }

    summaryCollectionView.emptyDataSetSource = self
    summaryCollectionView.emptyDataSetDelegate = self
  }

}

extension TransactionHistoryViewController { // Layout

  func showDetailCollectionView(_ shouldShow: Bool, animated: Bool) {
    let isHiddenOffset = detailCollectionViewHeight
    let multiplier: CGFloat = shouldShow ? -1 : 1
    detailCollectionViewTopConstraint.constant = (isHiddenOffset * multiplier)

    if animated {
      UIView.animate(withDuration: 0.3) {
        self.view.layoutIfNeeded()
      }

    } else {
      self.view.layoutIfNeeded()
    }
  }

  /// 20 for most devices, 44 on iPhone X
  private var statusBarHeight: CGFloat {
    return UIApplication.shared.statusBarFrame.height
  }

}

extension TransactionHistoryViewController: NSFetchedResultsControllerDelegate {
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    collectionViews.forEach { $0.reloadData() }
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

extension TransactionHistoryViewController: TransactionHistoryDetailCellDelegate {
  func shouldSaveMemo(for transaction: CKMTransaction) -> Promise<Void> {
    guard let delegate = coordinationDelegate else { return Promise { seal in seal.reject(CKPersistenceError.unexpectedResult)}}
    return delegate.viewControllerShouldUpdateTransaction(self, transaction: transaction)
  }

  func didTapAddMemoButton(completion: @escaping (String) -> Void) {
    coordinationDelegate?.viewControllerDidTapAddMemo(self, with: completion)
  }

  func didTapQuestionMarkButton(detailCell: TransactionHistoryDetailBaseCell, with url: URL) {
    urlOpener?.openURL(url, completionHandler: nil)
  }

  func didTapTwitterShare(detailCell: TransactionHistoryDetailBaseCell) {
    guard let path = self.detailCollectionView.indexPath(for: detailCell) else { return }
    let tx = frc.object(at: path)
    coordinationDelegate?.viewControllerRequestedShareTransactionOnTwitter(self, transaction: tx, shouldDismiss: false)
  }

  func didTapClose(detailCell: TransactionHistoryDetailBaseCell) {
    showDetailCollectionView(false, animated: true)
  }

  func didTapAddress(detailCell: TransactionHistoryDetailBaseCell) {
    guard let path = self.detailCollectionView.indexPath(for: detailCell),
      let address = self.detailViewModel(at: path).receiverAddress,
      let addressURL = CoinNinjaUrlFactory.buildUrl(for: .address(id: address))
      else { return }

    urlOpener?.openURL(addressURL, completionHandler: nil)
  }

  func didTapBottomButton(detailCell: TransactionHistoryDetailBaseCell, action: TransactionDetailAction) {
    guard let path = detailCollectionView.indexPath(for: detailCell) else { return }

    switch action {
    case .seeDetails:
      guard let viewModel = detailCell.viewModel else { return }
      coordinationDelegate?.viewControllerShouldSeeTransactionDetails(for: viewModel)
    case .cancelInvitation:
      guard let invitationID = frc.object(at: path).invitation?.id else { return }
      coordinationDelegate?.viewController(self, didCancelInvitationWithID: invitationID, at: path)
    }
  }
}

extension TransactionHistoryViewController: SendReceiveActionViewDelegate {
  func actionViewDidSelectReceive(_ view: UIView) {
    guard let coordinator = coordinationDelegate else { return }
    coordinator.viewControllerDidTapReceivePayment(self, converter: coordinator.currencyController.currencyConverter)
  }

  func actionViewDidSelectScan(_ view: UIView) {
    guard let coordinator = coordinationDelegate else { return }
    coordinator.viewControllerDidTapScan(self, converter: coordinator.currencyController.currencyConverter)
  }

  func actionViewDidSelectSend(_ view: UIView) {
    guard let coordinator = coordinationDelegate else { return }
    coordinator.viewControllerDidTapSendPayment(self, converter: coordinator.currencyController.currencyConverter)
  }
}

extension TransactionHistoryViewController: SelectedCurrencyUpdatable {
  func updateSelectedCurrency(to selectedCurrency: SelectedCurrency) {
    let summaryIndexSet = IndexSet(integersIn: (0..<summaryCollectionView.numberOfSections))
    summaryCollectionView.reloadSections(summaryIndexSet)
    detailCollectionView.reloadData()
  }
}

extension TransactionHistoryViewController: ExchangeRateUpdateable {

  func didUpdateExchangeRateManager(_ exchangeRateManager: ExchangeRateManager) {
    rateManager.exchangeRates = exchangeRateManager.exchangeRates
    coordinationDelegate?.currencyController.exchangeRates = exchangeRateManager.exchangeRates
    collectionViews.forEach { $0.reloadData() }
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
