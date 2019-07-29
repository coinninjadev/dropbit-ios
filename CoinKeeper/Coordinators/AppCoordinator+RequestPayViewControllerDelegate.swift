//
//  AppCoordinator+RequestPayViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol CopyToClipboardMessageDisplayable: AnyObject {
  func viewControllerSuccessfullyCopiedToClipboard(message: String, viewController: UIViewController)
}

extension AppCoordinator: RequestPayViewControllerDelegate {

  func viewControllerDidSelectSendRequest(_ viewController: UIViewController, payload: [Any]) {
    guard let requestPayVC = viewController as? RequestPayViewController else { return }
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
      if requestPayVC.isModal {
        requestPayVC.dismiss(animated: true, completion: nil)
      }
    }
    requestPayVC.present(controller, animated: true, completion: nil)
  }

  func viewControllerSuccessfullyCopiedToClipboard(message: String, viewController: UIViewController) {
    alertManager.showSuccess(message: message, forDuration: 2.0)
  }

  func viewControllerDidRequestNextReceiveAddress(_ viewController: UIViewController) -> String? {
    return nextReceiveAddressForRequestPay()
  }

  func selectedCurrencyPair() -> CurrencyPair {
    return CurrencyPair(primary: self.currencyController.selectedCurrencyCode,
                        fiat: self.currencyController.fiatCurrency)
  }

}
