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

  func viewControllerRequestedDropBitSendTweet(_ viewController: UIViewController,
                                               response: WalletAddressRequestResponse,
                                               tweetCompletion: @escaping TweetCompletionHandler) {
    let body = WalletAddressRequest(suppress: false)
    self.networkManager.updateWalletAddressRequest(for: response.id, with: body)
      .done(on: .main) { response in
        tweetCompletion(response.deliveryId)
        self.analyticsManager.track(event: .sendTweetViaDropBit, with: nil)
        viewController.dismiss(animated: true, completion: nil)
      }
      .catch { error in
        viewController.dismiss(animated: true) {
          let alert = self.alertManager.defaultAlert(withTitle: "Failed to send tweet", description: error.localizedDescription)
          self.navigationController.topViewController()?.present(alert, animated: true, completion: nil)
        }
    }
  }

  func viewControllerRequestedUserSendTweet(_ viewController: UIViewController, response: WalletAddressRequestResponse) {
    self.analyticsManager.track(event: .sendTweetManually, with: nil)

    guard let receiverHandle = response.metadata?.receiver?.handle, receiverHandle.isNotEmpty else {
      log.error("WalletAddressRequestResponse does not contain receiver's handle")
      return
    }

    let downloadURL = CoinNinjaUrlFactory.buildUrl(for: .download)?.absoluteString ?? ""
    let message = "\(receiverHandle) I just sent you Bitcoin using DropBit. Download the app to claim it here: \(downloadURL)"
    let shareSheet = UIActivityViewController(activityItems: [message], applicationActivities: nil)
    shareSheet.excludedActivityTypes = [
      .addToReadingList,
      .assignToContact,
      .markupAsPDF,
      .openInIBooks,
      .postToFacebook,
      .postToFlickr,
      .postToTencentWeibo,
      .postToVimeo,
      .postToWeibo,
      .saveToCameraRoll
    ]

    viewController.dismiss(animated: true, completion: {
      self.navigationController.topViewController()?.present(shareSheet, animated: true, completion: nil)
    })
  }

}
