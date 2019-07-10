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
import os.log
import PromiseKit
import PhoneNumberKit
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
}

class TransactionHistoryViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var summaryCollectionView: UICollectionView!
  @IBOutlet var summaryCollectionViewBottomConstraint: NSLayoutConstraint!
  @IBOutlet var detailCollectionView: UICollectionView!
  @IBOutlet var detailCollectionViewTopConstraint: NSLayoutConstraint!
  @IBOutlet var detailCollectionViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet var transactionHistoryNoBalanceView: TransactionHistoryNoBalanceView!
  @IBOutlet var transactionHistoryWithBalanceView: TransactionHistoryWithBalanceView!
  @IBOutlet var collectionViews: [UICollectionView]!
  @IBOutlet var refreshView: TransactionHistoryRefreshView!
  @IBOutlet var refreshViewTopConstraint: NSLayoutConstraint!
  @IBOutlet var sendReceiveActionView: SendReceiveActionView! {
    didSet {
      sendReceiveActionView.actionDelegate = self
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

  private let logger = OSLog(subsystem: "com.coinninja.coinkeeper.transactionhistoryviewcontroller", category: "tx_history_view_controller")

  private let phoneNumberKit = PhoneNumberKit()
  lazy var phoneFormatter: CKPhoneNumberFormatter = {
    return CKPhoneNumberFormatter(kit: self.phoneNumberKit, format: .national)
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

  var context: NSManagedObjectContext!

  lazy var frc: NSFetchedResultsController<CKMTransaction> = {
    let fetchRequest: NSFetchRequest<CKMTransaction> = CKMTransaction.fetchRequest()
    fetchRequest.sortDescriptors = CKMTransaction.transactionHistorySortDescriptors
    fetchRequest.fetchBatchSize = 25
    let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                managedObjectContext: context,
                                                sectionNameKeyPath: nil,
                                                cacheName: nil) // avoid caching unless there is real need as it is often the source of bugs
    os_log("starting fetch: %f", log: self.logger, type: .debug, Date().timeIntervalSinceReferenceDate)
    try? controller.performFetch()
    os_log("ending fetch: %f", log: self.logger, type: .debug, Date().timeIntervalSinceReferenceDate)
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

    view.layoutIfNeeded()
    let percent: CGFloat = 0.2
    sendReceiveActionView.fade(style: .top, percent: percent)
    detailCollectionViewHeightConstraint.constant = self.view.frame.height
    summaryCollectionViewBottomConstraint.constant = sendReceiveActionView.frame.height * percent * -1

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

  private func detailViewModel(at indexPath: IndexPath) -> TransactionHistoryDetailCellViewModel {
    let transaction = frc.object(at: indexPath)
    return TransactionHistoryDetailCellViewModel(
      transaction: transaction,
      rates: rateManager.exchangeRates,
      primaryCurrency: preferredCurrency(),
      deviceCountryCode: deviceCountryCode,
      kit: phoneNumberKit
    )
  }

  private func summaryViewModel(for transaction: CKMTransaction) -> TransactionHistorySummaryCellViewModel {
    return TransactionHistorySummaryCellViewModel(
      transaction: transaction,
      rates: rateManager.exchangeRates,
      primaryCurrency: preferredCurrency(),
      deviceCountryCode: deviceCountryCode,
      kit: phoneNumberKit
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

  private func showDetailCollectionView(_ shouldShow: Bool, animated: Bool) {
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

  private var detailCollectionViewHeight: CGFloat {
    return self.view.frame.height - statusBarHeight
  }

  private func summaryCollectionViewLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.minimumLineSpacing = 0
    layout.scrollDirection = .vertical
    return layout
  }

  private func detailCollectionViewLayout(withHorizontalPadding hPadding: CGFloat) -> UICollectionViewFlowLayout {
    let layout = HorizontallyPaginatedCollectionViewLayout()
    let itemHeight = detailCollectionViewHeight
    let itemWidth: CGFloat = self.view.frame.width - (hPadding * 2)
    layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
    layout.minimumInteritemSpacing = 0
    layout.minimumLineSpacing = 4
    layout.scrollDirection = .horizontal
    return layout
  }

}

extension TransactionHistoryViewController: UIScrollViewDelegate {

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView.contentOffset.y < 0 else { return }
    let offset = abs(scrollView.contentOffset.y)
    refreshViewTopConstraint.constant = offset
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

extension TransactionHistoryViewController: UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    guard collectionView == summaryCollectionView else { return CGSize(width: collectionView.frame.width - 16, height: collectionView.frame.height) }
    let transaction = frc.object(at: indexPath)
    var height: CGFloat = 66
    height += !transaction.isConfirmed ? 20 : 0
    height += (transaction.memo?.asNilIfEmpty() != nil) ? 25 : 0
    return CGSize(width: self.view.frame.width, height: height)
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

extension TransactionHistoryViewController: UICollectionViewDataSource {

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return self.frc.sections?.count ?? 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    guard let sections = frc.sections else { return 0 }
    let numberOfObjects = sections[section].numberOfObjects

    return numberOfObjects
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    switch collectionView {
    case summaryCollectionView:
      guard let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: TransactionHistorySummaryCell.reuseIdentifier,
        for: indexPath) as? TransactionHistorySummaryCell
        else { return UICollectionViewCell() }

      let transaction = frc.object(at: indexPath)

      let viewModel = summaryViewModel(for: transaction)

      cell.load(with: viewModel)

      return cell

    case detailCollectionView:
      let vm = detailViewModel(at: indexPath)

      if let invitation = vm.transaction?.invitation {
        switch invitation.status {
        case .canceled, .expired:
          let cell = detailCollectionView.dequeue(TransactionHistoryDetailInvalidCell.self, for: indexPath)
          cell.load(with: vm, delegate: self)
          return cell
        default:
          let cell = detailCollectionView.dequeue(TransactionHistoryDetailValidCell.self, for: indexPath)
          cell.load(with: vm, delegate: self)
          return cell
        }
      } else {
        let cell = detailCollectionView.dequeue(TransactionHistoryDetailValidCell.self, for: indexPath)
        cell.load(with: vm, delegate: self)
        return cell
      }

    default:
      return UICollectionViewCell()
    }
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

extension TransactionHistoryViewController: UICollectionViewDelegate {

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    switch collectionView {
    case summaryCollectionView:

      // Show detail collection view scrolled to the same indexPath as the selected summary cell
      let indexPaths = collectionView.indexPathsForVisibleItems
      detailCollectionView.reloadItems(at: indexPaths)
      detailCollectionView.scrollToItem(at: indexPath, at: .left, animated: false)
      showDetailCollectionView(true, animated: true)

    case detailCollectionView:
      collectionView.deselectItem(at: indexPath, animated: false)
    default:
      break
    }
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
