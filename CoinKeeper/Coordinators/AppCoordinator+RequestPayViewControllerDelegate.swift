//
//  AppCoordinator+RequestPayViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: RequestPayViewControllerDelegate {

  func viewControllerDidSelectSendRequest(_ viewController: UIViewController, payload: [Any]) {
    analyticsManager.track(event: .sendRequestButtonPressed, with: nil)
    let controller = UIActivityViewController(activityItems: payload, applicationActivities: nil)
    controller.excludedActivityTypes = [
      .addToReadingList,
      .assignToContact,
      .markupAsPDF,
      .openInIBooks,
      .postToFacebook,
      .postToFlickr,
      .postToTencentWeibo,
      .postToTwitter,
      .postToVimeo,
      .postToWeibo,
      .saveToCameraRoll
    ]
    controller.completionWithItemsHandler = { _, _, _, _ in
      viewController.dismiss(animated: true, completion: nil)
    }
    viewController.present(controller, animated: true, completion: nil)
  }

  func viewControllerSuccessfullyCopiedToClipboard(_ viewController: UIViewController) {
    alertManager.showSuccess(message: "Address copied to clipboard!", forDuration: 2.0)
  }

}
