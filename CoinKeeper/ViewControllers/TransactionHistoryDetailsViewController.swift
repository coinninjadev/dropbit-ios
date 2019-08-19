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

protocol TransactionHistoryDetailsViewControllerDelegate: TransactionShareable {
  func viewControllerDidDismissTransactionDetails(_ viewController: UIViewController)
  func viewControllerShouldSeeTransactionDetails(for viewModel: TransactionHistoryDetailCellViewModel)
  func viewController(_ viewController: TransactionHistoryDetailsViewController,
                      didCancelInvitationWithID invitationID: String,
                      at indexPath: IndexPath)
  func viewControllerDidTapAddMemo(_ viewController: UIViewController, with completion: @escaping (String) -> Void)
  func viewControllerShouldUpdateTransaction(_ viewController: TransactionHistoryDetailsViewController,
                                             transaction: CKMTransaction) -> Promise<Void>
}

final class TransactionHistoryDetailsViewController: PresentableViewController, StoryboardInitializable {

  @IBOutlet var collectionView: TransactionHistoryDetailCollectionView! {
    didSet {
      if onChainFetchResultsController == nil {
        let delegateAndDataSource = TransactionHistoryDetailsViewControllerOnChainDDS(viewController: self)
        collectionView.dataSource = delegateAndDataSource
        collectionView.delegate = delegateAndDataSource
      } else {
        let delegateAndDataSource = TransactionHistoryDetailsViewControllerLightningDDS(viewController: self)
        collectionView.dataSource = delegateAndDataSource
        collectionView.delegate = delegateAndDataSource
      }

      collectionView.showsHorizontalScrollIndicator = false
    }
  }
  weak var urlOpener: URLOpener?
  weak var onChainFetchResultsController: NSFetchedResultsController<CKMTransaction>?
  weak var lightningFetchResultsController: NSFetchedResultsController<CKMWalletEntry>?
  var selectedIndexPath: IndexPath = IndexPath(item: 0, section: 0)
  var viewModelForIndexPath: ((IndexPath) -> TransactionHistoryDetailCellViewModel)?

  static func newInstance(withDelegate delegate: TransactionHistoryDetailsViewControllerDelegate,
                          fetchedResultsController frc: NSFetchedResultsController<CKMTransaction>,
                          selectedIndexPath: IndexPath,
                          viewModelForIndexPath: @escaping (IndexPath) -> TransactionHistoryDetailCellViewModel,
                          urlOpener: URLOpener) -> TransactionHistoryDetailsViewController {
    let controller = TransactionHistoryDetailsViewController.makeFromStoryboard()
    controller.onChainFetchResultsController = frc
    controller.generalCoordinationDelegate = delegate
    controller.selectedIndexPath = selectedIndexPath
    controller.viewModelForIndexPath = viewModelForIndexPath
    controller.urlOpener = urlOpener
    return controller
  }

  static func newInstance(withDelegate delegate: TransactionHistoryDetailsViewControllerDelegate,
                          fetchedResultsController frc: NSFetchedResultsController<CKMWalletEntry>,
                          selectedIndexPath: IndexPath,
                          viewModelForIndexPath: @escaping (IndexPath) -> TransactionHistoryDetailCellViewModel,
                          urlOpener: URLOpener) -> TransactionHistoryDetailsViewController {
    let controller = TransactionHistoryDetailsViewController.makeFromStoryboard()
    controller.lightningFetchResultsController = frc
    controller.generalCoordinationDelegate = delegate
    controller.selectedIndexPath = selectedIndexPath
    controller.viewModelForIndexPath = viewModelForIndexPath
    controller.urlOpener = urlOpener
    return controller
  }

  var coordinationDelegate: TransactionHistoryDetailsViewControllerDelegate? {
    return generalCoordinationDelegate as? TransactionHistoryDetailsViewControllerDelegate
  }

  override var cornerRadius: CGFloat {
    get { return .zero }
    set { super.cornerRadius = newValue }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    collectionView.registerNib(cellType: TransactionHistoryDetailValidCell.self)
    collectionView.registerNib(cellType: TransactionHistoryDetailInvalidCell.self)

    if #available(iOS 11.0, *) {
      self.collectionView.contentInsetAdjustmentBehavior = .never
    }

    let hPadding: CGFloat = 8 // amount of space between cell edge and screen edge, to allow showing previous/next cell
    collectionView.contentInset = UIEdgeInsets(top: 0, left: hPadding, bottom: 0, right: hPadding) // allow first and last cells to be centered
    collectionView.isPagingEnabled = true
    collectionView.collectionViewLayout = detailCollectionViewLayout(withHorizontalPadding: hPadding)
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

  func didTapQuestionMark(detailCell: TransactionHistoryDetailBaseCell) {
    //TODO: get indexPath, viewModel, and url
//    urlOpener?.openURL(url, completionHandler: nil)
  }

  func didTapClose(detailCell: TransactionHistoryDetailBaseCell) {
    coordinationDelegate?.viewControllerDidDismissTransactionDetails(self)
  }

  func didTapTwitterShare(detailCell: TransactionHistoryDetailBaseCell) {
    //TODO
//    guard let tx = detailCell.viewModel?.transaction else { return }
//    coordinationDelegate?.viewControllerRequestedShareTransactionOnTwitter(self, transaction: tx, shouldDismiss: false)
  }

  func didTapAddress(detailCell: TransactionHistoryDetailBaseCell) {
    //TODO
//    guard let address = detailCell.viewModel?.receiverAddress,
//      let addressURL = CoinNinjaUrlFactory.buildUrl(for: .address(id: address)) else { return }
//    urlOpener?.openURL(addressURL, completionHandler: nil)
  }

  func didTapBottomButton(detailCell: TransactionHistoryDetailBaseCell, action: TransactionDetailAction) {
    switch action {
      //TODO
//    case .seeDetails:
//      guard let viewModel = detailCell.viewModel else { return }
//      coordinationDelegate?.viewControllerShouldSeeTransactionDetails(for: viewModel)
//    case .cancelInvitation:
//      guard let invitationID = detailCell.viewModel?.transaction?.invitation?.id,
//        let path = collectionView.indexPath(for: detailCell) else { return }
//      coordinationDelegate?.viewController(self, didCancelInvitationWithID: invitationID, at: path)
    default:
      break
    }
  }

  func didTapAddMemo(detailCell: TransactionHistoryDetailBaseCell) {
    coordinationDelegate?.viewControllerDidTapAddMemo(self) { memo in
      //TODO
//      guard let vm = self?.viewModel, let delegate = self?.delegate, let tx = vm.transaction else { return }
//      tx.memo = memo
//
//      delegate.shouldSaveMemo(for: tx)
//        .done {
//          vm.memo = memo
//          self?.load(with: vm, delegate: delegate)
//        }.catch { error in
//          log.error(error, message: "failed to add memo")
//      }
    }
  }

  func shouldSaveMemo(for transaction: CKMTransaction) -> Promise<Void> {
    guard let delegate = coordinationDelegate else { return Promise(error: CKPersistenceError.unexpectedResult) }
    return delegate.viewControllerShouldUpdateTransaction(self, transaction: transaction)
  }

}

class TransactionHistoryDetailCollectionView: UICollectionView {}
