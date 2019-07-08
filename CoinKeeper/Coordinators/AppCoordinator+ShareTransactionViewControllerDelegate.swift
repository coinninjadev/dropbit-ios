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
                                                        transaction: CKMTransaction?,
                                                        shouldDismiss: Bool) {
    self.analyticsManager.track(event: .sharePromptTwitter, with: nil)

    if shouldDismiss {
      viewController.dismiss(animated: true) {
        self.shareTransactionOnTwitter(transaction)
      }
    } else {
      shareTransactionOnTwitter(transaction)
    }
  }

  private func shareTransactionOnTwitter(_ transaction: CKMTransaction?) {
    var defaultTweetText = ""
    if let tx = transaction {
      defaultTweetText = self.tweetText(withMemo: tx.memo)
    } else {
      let bgContext = self.persistenceManager.createBackgroundContext()
      bgContext.performAndWait {
        let latestTx = self.persistenceManager.databaseManager.latestTransaction(in: bgContext)
        defaultTweetText = self.tweetText(withMemo: latestTx?.memo)
      }
    }

    self.openTwitterURL(withMessage: defaultTweetText)
  }

  /// Create and open `twitter:` URL to begin a post in the Twitter app with the provided message
  func openTwitterURL(withMessage message: String) {
    var comps = URLComponents()
    comps.scheme = "twitter"
    comps.host = "post"
    comps.queryItems = [URLQueryItem(name: "message", value: message)]
    if let url = comps.url {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    } else {
      log.error("Failed to create Twitter URL from components")
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
