//
//  AppCoordinator+TweetMethodViewControllerDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 5/30/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: TweetMethodViewControllerDelegate {

  func viewControllerRequestedUserSendTweet(_ viewController: UIViewController,
                                            response: WalletAddressRequestResponse,
                                            method: NotifyRecipientMethod) {
    self.analyticsManager.track(event: .sendTweetManually, with: nil)
    let message = self.tweetMessage(for: response)

    viewController.dismiss(animated: true, completion: {
      switch method {
      case .twitterApp:
        self.openTwitterURL(withMessage: message)
      case .shareSheet:
        self.showShareSheet(withMessage: message)
      }
    })
  }

  private func showShareSheet(withMessage message: String) {
    let shareSheet = UIActivityViewController(activityItems: [message], applicationActivities: nil)
    shareSheet.excludedActivityTypes = UIActivity.standardExcludedTypes

    self.navigationController.topViewController()?.present(shareSheet, animated: true, completion: nil)
  }

  private func tweetMessage(for response: WalletAddressRequestResponse) -> String {
    let maybeReceiverHandle = response.metadata?.receiver?.handle
    if maybeReceiverHandle?.asNilIfEmpty() == nil {
      log.error("WalletAddressRequestResponse does not contain receiver's handle")
    }

    let receiverHandle = maybeReceiverHandle ?? "[enter @recipient]"
    let downloadURL = CoinNinjaUrlFactory.buildUrl(for: .download)?.absoluteString ?? ""
    let message = "\(receiverHandle) I just sent you Bitcoin using DropBit. Download the app to claim it here: \(downloadURL)"
    return message
  }

}
