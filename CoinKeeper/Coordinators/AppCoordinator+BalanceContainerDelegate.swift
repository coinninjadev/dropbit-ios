//
//  AppCoordinator+BalanceContainerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import CoreData

extension AppCoordinator: BalanceContainerDelegate {
  func isSyncCurrentlyRunning() -> Bool {
    let syncOperations = serialQueueManager.queue.operations(ofType: .syncWallet(.standard),
                                                             ignoringAssociatedType: true)
    return syncOperations.isNotEmpty
  }

  func containerDidTapLeftButton(in viewController: UIViewController) {
    switch viewController {
    case is TransactionHistoryViewController:
      self.navigationController.popViewController(animated: true)

    case is CalculatorViewController:
      self.drawerController?.toggle(.left, animated: true, completion: nil)

    default:
      break
    }
  }

  func containerDidTapBalances(in viewController: UIViewController) {
    switch viewController {
    case is TransactionHistoryViewController:
      break
    case is CalculatorViewController:
      analyticsManager.track(event: .balanceHistoryButtonPressed, with: nil)
      self.pushTransactionHistory()
    default:
      break
    }
  }

  func containerDidLongPressBalances(in viewController: UIViewController) {
    //
  }

}

extension AppCoordinator {

  fileprivate func deleteAllTransactionsAndRelatedObjects(in context: NSManagedObjectContext) {
    CKMTransaction.deleteAll(in: context)
    CKMPhoneNumber.deleteAll(in: context)
    CKMAddressTransactionSummary.deleteAll(in: context)
    CKMCounterpartyAddress.deleteAll(in: context)
    CKMAddress.deleteAll(in: context)
  }

  // Not called currently, but may be useful for testing UI
  fileprivate func generateSampleData() {
    let context = persistenceManager.mainQueueContext()
    guard let wallet = CKMWallet.find(in: context) else { return }

    if wallet.addressTransactionSummaries.isEmpty { //alternate between deletion and creation
      SampleTransaction.history.forEach({
        _ = CKMTransaction(sampleTx: $0, wallet: wallet, insertInto: context)
      })

    } else {
      deleteAllTransactionsAndRelatedObjects(in: context)
    }

    try? context.save()
  }

}
