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
URLOpener & DeviceCountryCodeProvider & CurrencyValueDataSourceType {

  var currencyController: CurrencyController { get }
  func viewControllerDidDismissTransactionDetails(_ viewController: UIViewController)
  func viewControllerShouldSeeTransactionDetails(for viewModel: OldTransactionDetailCellViewModel)
  func viewController(_ viewController: TransactionHistoryDetailsViewController,
                      didCancelInvitationWithID invitationID: String,
                      at indexPath: IndexPath)
  func viewControllerDidTapAddMemo(_ viewController: UIViewController, with completion: @escaping (String) -> Void)
  func viewControllerShouldUpdateTransaction(_ viewController: TransactionHistoryDetailsViewController,
                                             transaction: CKMTransaction) -> Promise<Void>
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

  func didTapQuestionMarkButton(detailCell: TransactionHistoryDetailBaseCell, tooltip: DetailCellTooltip) {
    guard let tooltipURL = url(for: tooltip) else { return }
    delegate.openURL(url, completionHandler: nil)
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
//    guard let tx = detailCell.viewModel?.transaction else { return }
//    delegate.viewControllerRequestedShareTransactionOnTwitter(self, transaction: tx, shouldDismiss: false)
  }

  func didTapAddress(detailCell: TransactionHistoryDetailBaseCell) {
//    guard let address = detailCell.viewModel?.receiverAddress,
//      let addressURL = CoinNinjaUrlFactory.buildUrl(for: .address(id: address)) else { return }
//    delegate.openURL(addressURL, completionHandler: nil)
  }

  func didTapInvoice(detailCell: TransactionHistoryDetailInvoiceCell) {

  }

  func didTapBottomButton(detailCell: UICollectionViewCell, action: TransactionDetailAction) {
//    switch action {
//    case .seeDetails:
//      guard let viewModel = detailCell.viewModel else { return }
//      delegate.viewControllerShouldSeeTransactionDetails(for: viewModel)
//    case .cancelInvitation:
//      guard let invitationID = detailCell.viewModel?.transaction?.invitation?.id,
//        let path = collectionView.indexPath(for: detailCell) else { return }
//      delegate.viewController(self, didCancelInvitationWithID: invitationID, at: path)
//    }
  }

  func didTapAddMemoButton(detailCell: TransactionHistoryDetailBaseCell) {
//    delegate.viewControllerDidTapAddMemo(self, with: completion)
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
