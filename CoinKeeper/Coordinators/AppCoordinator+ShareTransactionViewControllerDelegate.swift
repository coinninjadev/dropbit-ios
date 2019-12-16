//
//  AppCoordinator+ShareTransactionViewControllerDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 4/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: ShareTransactionViewControllerDelegate {

  func viewControllerRequestedShareTransactionOnTwitter(_ viewController: UIViewController,
                                                        walletTxType: WalletTransactionType,
                                                        transaction: TransactionDetailCellActionable?,
                                                        shouldDismiss: Bool) {
    self.analyticsManager.track(event: .sharePromptTwitter, with: nil)

    if shouldDismiss {
      viewController.dismiss(animated: true) {
        self.shareTransactionOnTwitter(transaction, walletTxType: walletTxType)
      }
    } else {
      shareTransactionOnTwitter(transaction, walletTxType: walletTxType)
    }
  }

  private func shareTransactionOnTwitter(_ transaction: TransactionDetailCellActionable?,
                                         walletTxType: WalletTransactionType) {
    var defaultTweetText = ""
    if let tx = transaction {
      defaultTweetText = self.tweetText(withMemo: tx.memo)
    } else {
      switch walletTxType {
      case .onChain:
        let bgContext = self.persistenceManager.createBackgroundContext()
        bgContext.perform { [weak self] in
          guard let strongSelf = self else { return }
          let latestTx = strongSelf.persistenceManager.databaseManager.latestTransaction(in: bgContext)
          defaultTweetText = strongSelf.tweetText(withMemo: latestTx?.memo)
          DispatchQueue.main.async {
            strongSelf.openTwitterURL(withMessage: defaultTweetText)
          }
        }
      case .lightning:
        //skip fetching latest lightning wallet entry for now
        defaultTweetText = self.tweetText(withMemo: nil)
        self.openTwitterURL(withMessage: defaultTweetText)
      }
    }

  }

  func viewControllerRequestedShareNextTime(_ viewController: UIViewController) {
    self.analyticsManager.track(event: .sharePromptNextTime, with: nil)
    viewController.dismiss(animated: true, completion: nil)
  }

  private func tweetText(withMemo memo: String?) -> String {
    let randomInt = Int.random(in: 0...1)
    if let memoText = memo?.lowercasingFirstLetter() {
      if randomInt == 0 {
        return "I just used #Bitcoin for \(memoText) via @dropbitapp"
      } else {
        return "Today I used #Bitcoin for \(memoText) via @dropbitapp"
      }
    } else {
      if randomInt == 0 {
        return "I just used #Bitcoin instead of fiat via @dropbitapp"
      } else {
        return "I just sent #Bitcoin using @dropbitapp and wow was that easy!"
      }
    }
  }

}
