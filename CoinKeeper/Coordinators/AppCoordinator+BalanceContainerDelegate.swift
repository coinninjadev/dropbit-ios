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
    self.drawerController?.toggle(.left, animated: true, completion: nil)
  }

  func containerDidTapDropBitMe(in viewController: UIViewController, buttonImageFrame: CGRect) {
    guard let topVC = self.navigationController.topViewController() else { return }

    var config: DropBitMeConfig = .notVerified
    if let phoneHash = self.verifiedPhoneNumberHash(),
      let url = CoinNinjaUrlFactory.buildUrl(for: .dropBitMe(phoneNumberHash: phoneHash, twitterUsername: nil)) {
      config = .verified(url, false)
    }

    let dropBitMeVC = DropBitMeViewController.newInstance(config: config, avatarFrame: buttonImageFrame, delegate: self)
    topVC.present(dropBitMeVC, animated: true, completion: nil)
  }

  func verifiedPhoneNumberHash() -> String? {
    let hasher = HashingManager()
    guard let phoneNumber = self.persistenceManager.verifiedPhoneNumber(),
      let salt = try? hasher.salt() else { return nil }

    return hasher.hash(phoneNumber: phoneNumber, salt: salt, parsedNumber: nil, kit: self.phoneNumberKit)
  }

  func containerDidTapBalances(in viewController: UIViewController) {
    if let txHistory = viewController as? TransactionHistoryViewController {
      // save to user defaults
      currencyController.selectedCurrency.toggle()
      persistenceManager.setSelectedCurrency(currencyController.selectedCurrency)

      // tell tx history to reload from user defaults
      txHistory.updateSelectedCurrency(to: currencyController.selectedCurrency)
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

  func selectedCurrency() -> SelectedCurrency {
    return currencyController.selectedCurrency
  }
}
