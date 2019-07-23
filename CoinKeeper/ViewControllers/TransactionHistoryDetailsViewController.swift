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
  func viewController(_ viewController: TransactionHistoryDetailsViewController, didCancelInvitationWithID invitationID: String, at indexPath: IndexPath)
  func viewControllerDidTapAddMemo(_ viewController: UIViewController, with completion: @escaping (String) -> Void)
  func viewControllerShouldUpdateTransaction(_ viewController: TransactionHistoryDetailsViewController,
                                             transaction: CKMTransaction) -> Promise<Void>
}

final class TransactionHistoryDetailsViewController: BaseViewController,
StoryboardInitializable {

  @IBOutlet var collectionView: TransactionHistoryDetailCollectionView! {
    didSet {
      collectionView.dataSource = self
      collectionView.delegate = self.collectionViewDelegate
    }
  }
  weak var urlOpener: URLOpener?
  weak var frc: NSFetchedResultsController<CKMTransaction>?
  weak var collectionViewDelegate: UICollectionViewDelegate?
  var viewModelForIndexPath: ((IndexPath) -> TransactionHistoryDetailCellViewModel)?

  static func newInstance(withDelegate delegate: TransactionHistoryDetailsViewControllerDelegate,
                          collectionViewDelegate: UICollectionViewDelegate,
                          fetchedResultsController frc: NSFetchedResultsController<CKMTransaction>,
                          viewModelForIndexPath: @escaping (IndexPath) -> TransactionHistoryDetailCellViewModel,
                          urlOpener: URLOpener) -> TransactionHistoryDetailsViewController {
    let controller = TransactionHistoryDetailsViewController.makeFromStoryboard()
    controller.modalTransitionStyle = .coverVertical
    controller.modalPresentationStyle = .overFullScreen
    controller.generalCoordinationDelegate = delegate
    controller.collectionViewDelegate = collectionViewDelegate
    controller.frc = frc
    controller.viewModelForIndexPath = viewModelForIndexPath
    controller.urlOpener = urlOpener
    return controller
  }

  var coordinationDelegate: TransactionHistoryDetailsViewControllerDelegate? {
    return generalCoordinationDelegate as? TransactionHistoryDetailsViewControllerDelegate
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    collectionView.registerNib(cellType: TransactionHistoryDetailValidCell.self)
    collectionView.registerNib(cellType: TransactionHistoryDetailInvalidCell.self)

    if #available(iOS 11.0, *) {
      self.collectionView.contentInsetAdjustmentBehavior = .never
    }

    let hPadding: CGFloat = 8 // amount of space between cell edge and screen edge, to allow showing previous/next cell
    collectionView.contentInset = UIEdgeInsets(top: 0, left: hPadding, bottom: 0, right: hPadding) // allow first and last cells to be centered
    collectionView.isPagingEnabled = false
    collectionView.collectionViewLayout = detailCollectionViewLayout(withHorizontalPadding: hPadding)
    collectionView.backgroundColor = .clear
  }

  private var detailCollectionViewHeight: CGFloat {
    return self.view.frame.height
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

extension TransactionHistoryDetailsViewController: TransactionHistoryDetailCellDelegate {
  func didTapQuestionMarkButton(detailCell: TransactionHistoryDetailBaseCell, with url: URL) {
    urlOpener?.openURL(url, completionHandler: nil)
  }

  func didTapClose(detailCell: TransactionHistoryDetailBaseCell) {
    coordinationDelegate?.viewControllerDidDismissTransactionDetails(self)
  }

  func didTapTwitterShare(detailCell: TransactionHistoryDetailBaseCell) {
    guard let tx = detailCell.viewModel?.transaction else { return }
    coordinationDelegate?.viewControllerRequestedShareTransactionOnTwitter(self, transaction: tx, shouldDismiss: false)
  }

  func didTapAddress(detailCell: TransactionHistoryDetailBaseCell) {
    guard let address = detailCell.viewModel?.receiverAddress,
      let addressURL = CoinNinjaUrlFactory.buildUrl(for: .address(id: address)) else { return }
    urlOpener?.openURL(addressURL, completionHandler: nil)
  }

  func didTapBottomButton(detailCell: TransactionHistoryDetailBaseCell, action: TransactionDetailAction) {
    switch action {
    case .seeDetails:
      guard let viewModel = detailCell.viewModel else { return }
      coordinationDelegate?.viewControllerShouldSeeTransactionDetails(for: viewModel)
    case .cancelInvitation:
      guard let invitationID = detailCell.viewModel?.transaction?.invitation?.id,
        let path = collectionView.indexPath(for: detailCell) else { return }
      coordinationDelegate?.viewController(self, didCancelInvitationWithID: invitationID, at: path)
    }
  }

  func didTapAddMemoButton(completion: @escaping (String) -> Void) {
    coordinationDelegate?.viewControllerDidTapAddMemo(self, with: completion)
  }

  func shouldSaveMemo(for transaction: CKMTransaction) -> Promise<Void> {
    guard let delegate = coordinationDelegate else { return Promise(error: CKPersistenceError.unexpectedResult) }
    return delegate.viewControllerShouldUpdateTransaction(self, transaction: transaction)
  }

}

extension TransactionHistoryDetailsViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return frc?.fetchedObjects?.count ?? 0
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let viewModel = viewModelForIndexPath?(indexPath) else { return UICollectionViewCell() }

    if let invitation = viewModel.transaction?.invitation {
      switch invitation.status {
      case .canceled, .expired:
        let cell = collectionView.dequeue(TransactionHistoryDetailInvalidCell.self, for: indexPath)
        cell.load(with: viewModel, delegate: self)
        return cell
      default:
        let cell = collectionView.dequeue(TransactionHistoryDetailValidCell.self, for: indexPath)
        cell.load(with: viewModel, delegate: self)
        return cell
      }
    } else {
      let cell = collectionView.dequeue(TransactionHistoryDetailValidCell.self, for: indexPath)
      cell.load(with: viewModel, delegate: self)
      return cell
    }
  }
}

class TransactionHistoryDetailCollectionView: UICollectionView {}
