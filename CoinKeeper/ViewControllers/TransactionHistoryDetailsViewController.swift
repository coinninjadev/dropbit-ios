//
//  TransactionHistoryDetailsViewController.swift
//  DropBit
//
//  Created by BJ Miller on 7/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import CoreData
import PromiseKit

protocol TransactionHistoryDetailsViewControllerDelegate: TransactionShareable &
URLOpener & DeviceCountryCodeProvider & CurrencyValueDataSourceType & CopyToClipboardMessageDisplayable {

  var currencyController: CurrencyController { get }
  func viewControllerDidDismissTransactionDetails(_ viewController: UIViewController)
  func viewControllerShouldSeeTransactionDetails(for viewModel: TransactionDetailPopoverDisplayable)
  func viewController(_ viewController: TransactionHistoryDetailsViewController,
                      didCancelInvitationWithID invitationID: String,
                      at indexPath: IndexPath)
  func viewControllerDidTapAddMemo(_ viewController: UIViewController, with completion: @escaping (String) -> Void)
}

final class TransactionHistoryDetailsViewController: PresentableViewController, StoryboardInitializable {

  @IBOutlet var collectionView: TransactionHistoryDetailCollectionView!

  var viewModel: TransactionHistoryViewModel!

  var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)

  static func newInstance(withDelegate delegate: TransactionHistoryDetailsViewControllerDelegate,
                          walletTxType: WalletTransactionType,
                          selectedIndexPath: IndexPath,
                          dataSource: TransactionHistoryDataSourceType) -> TransactionHistoryDetailsViewController {
    let vc = TransactionHistoryDetailsViewController.makeFromStoryboard()
    vc.delegate = delegate
    vc.selectedIndexPath = selectedIndexPath
    dataSource.delegate = vc
    vc.viewModel = TransactionHistoryViewModel(delegate: vc,
                                               detailsDelegate: vc,
                                               currencyManager: delegate,
                                               deviceCountryCode: delegate.deviceCountryCode(),
                                               transactionType: walletTxType,
                                               dataSource: dataSource)
    return vc
  }

  private(set) weak var delegate: TransactionHistoryDetailsViewControllerDelegate!

  override var cornerRadius: CGFloat {
    get { return .zero }
    set { super.cornerRadius = newValue }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    collectionView.registerNib(cellType: TransactionHistoryDetailValidCell.self)
    collectionView.registerNib(cellType: TransactionHistoryDetailInvalidCell.self)
    collectionView.registerNib(cellType: TransactionHistoryDetailInvoiceCell.self)
    collectionView.delegate = self
    collectionView.dataSource = self.viewModel

    if #available(iOS 11.0, *) {
      self.collectionView.contentInsetAdjustmentBehavior = .never
    }

    let hPadding: CGFloat = 8 // amount of space between cell edge and screen edge, to allow showing previous/next cell
    collectionView.contentInset = UIEdgeInsets(top: 0, left: hPadding, bottom: 0, right: hPadding) // allow first and last cells to be centered
    collectionView.isPagingEnabled = true
    collectionView.collectionViewLayout = detailCollectionViewLayout(withHorizontalPadding: hPadding)
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.backgroundColor = .clear
    collectionView.reloadData()
  }

  var detailCollectionViewHeight: CGFloat {
    return presentationController?.frameOfPresentedViewInContainerView.size.height ?? .zero
  }

  func detailCollectionViewLayout(withHorizontalPadding hPadding: CGFloat) -> UICollectionViewFlowLayout {
    let layout = HorizontallyPaginatedCollectionViewLayout()
    layout.minimumInteritemSpacing = 0
    layout.minimumLineSpacing = 4
    layout.scrollDirection = .horizontal
    return layout
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    collectionView.layoutIfNeeded()
    collectionView.scrollToItem(at: selectedIndexPath, at: .centeredHorizontally, animated: false)
  }

}

extension TransactionHistoryDetailsViewController: TransactionHistoryDetailCellDelegate {

  private func actionableItem(for detailCell: UICollectionViewCell) -> TransactionDetailCellActionable? {
    guard let indexPath = self.collectionView.indexPath(for: detailCell) else { return nil }
    return viewModel.dataSource.detailCellActionableItem(at: indexPath)
  }

  func didTapQuestionMarkButton(detailCell: TransactionHistoryDetailBaseCell, tooltip: DetailCellTooltip) {
    guard let tooltipURL = url(for: tooltip) else { return }
    delegate.openURL(tooltipURL, completionHandler: nil)
  }

  private func url(for tooltip: DetailCellTooltip) -> URL? {
    switch tooltip {
    case .dropBit:          return CoinNinjaUrlFactory.buildUrl(for: .dropbitTransactionTooltip)
    case .regularOnChain:   return CoinNinjaUrlFactory.buildUrl(for: .regularTransactionTooltip)
    }
  }

  func didTapClose(detailCell: UICollectionViewCell) {
    delegate.viewControllerDidDismissTransactionDetails(self)
  }

  func didTapTwitterShare(detailCell: TransactionHistoryDetailBaseCell) {
    guard let item = actionableItem(for: detailCell) else { return }
    delegate.viewControllerRequestedShareTransactionOnTwitter(self, walletTxType: self.viewModel.walletTransactionType,
                                                              transaction: item, shouldDismiss: false)
  }

  func didTapAddressLinkButton(detailCell: TransactionHistoryDetailBaseCell) {
    guard let item = actionableItem(for: detailCell),
      let address = item.bitcoinAddress,
      let addressURL = CoinNinjaUrlFactory.buildUrl(for: .address(id: address))
      else { return }
    delegate.openURL(addressURL, completionHandler: nil)
  }

  func didTapCopyInvoiceButton(detailCell: TransactionHistoryDetailInvoiceCell) {
    guard let item = actionableItem(for: detailCell), let invoice = item.lightningInvoice else { return }
    UIPasteboard.general.string = invoice
    delegate.viewControllerSuccessfullyCopiedToClipboard(message: "Lightning invoice copied!", viewController: self)
  }

  func didTapBottomButton(detailCell: UICollectionViewCell, action: TransactionDetailAction) {
    guard let indexPath = self.collectionView.indexPath(for: detailCell),
      let item = viewModel.dataSource.detailCellActionableItem(at: indexPath) else { return }
    switch action {
    case .seeDetails:
      guard let popoverItem = viewModel.popoverDisplayableItem(at: indexPath) else { return }
      delegate.viewControllerShouldSeeTransactionDetails(for: popoverItem)

    case .cancelInvitation:
      guard let invitationID = item.invitation?.id else { return }
      delegate.viewController(self, didCancelInvitationWithID: invitationID, at: indexPath)
    case .removeEntry:
      item.removeFromTransactionHistory()
      updateItem(item)
      delegate.viewControllerDidDismissTransactionDetails(self)
    }
  }

  func didTapAddMemoButton(detailCell: TransactionHistoryDetailBaseCell) {
//    delegate.viewControllerDidTapAddMemo(self, with: completion)
  }

  private func updateItem(_ item: TransactionDetailCellActionable) {
    guard let context = item.managedObjectContext else { return }

    do {
      try context.saveRecursively()
    } catch {
      log.contextSaveError(error)
    }
  }

}

class TransactionHistoryDetailCollectionView: UICollectionView {}

extension TransactionHistoryDetailsViewController: TransactionHistoryDataSourceDelegate {
  func transactionDataSourceWillChange() { }
  func transactionDataSourceDidChange() { }
}

extension TransactionHistoryDetailsViewController: TransactionHistoryViewModelDelegate {
  var currencyController: CurrencyController {
    return delegate.currencyController
  }

  func viewModelDidUpdateExchangeRates() {

  }

  func summaryHeaderType() -> SummaryHeaderType? {
    return nil
  }

  func didTapSummaryHeader(_ header: TransactionHistorySummaryHeader) { }

}
