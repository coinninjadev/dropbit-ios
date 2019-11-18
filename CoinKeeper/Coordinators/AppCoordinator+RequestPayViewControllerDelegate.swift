//
//  AppCoordinator+RequestPayViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PromiseKit

protocol CopyToClipboardMessageDisplayable: AnyObject {
  func viewControllerSuccessfullyCopiedToClipboard(message: String, viewController: UIViewController)
}

extension AppCoordinator: RequestPayViewControllerDelegate {

  func viewControllerDidCreateInvoice(_ viewController: UIViewController) {
    guard let txDataWorker = workerFactory().createTransactionDataWorker() else { return }

    let context = persistenceManager.createBackgroundContext()
    context.perform {
      txDataWorker.performFetchAndStoreAllLightningTransactions(in: context, fullSync: false)
        .done(in: context) {
          try? context.saveRecursively()
          DispatchQueue.main.async {
            CKNotificationCenter.publish(key: .didUpdateLocalTransactionRecords)
          }
      }.cauterize()
    }
  }

  func viewControllerDidSelectCreateInvoice(_ viewController: UIViewController,
                                            forAmount sats: Int,
                                            withMemo memo: String?) -> Promise<LNCreatePaymentRequestResponse> {
    return networkManager.createLightningPaymentRequest(sats: sats, expires: Int(TimeInterval.twoDays), memo: memo)
  }

  func viewControllerDidSelectSendRequest(_ viewController: UIViewController, payload: [Any]) {
    guard let requestPayVC = viewController as? RequestPayViewController else { return }
    analyticsManager.track(event: .sendRequestButtonPressed, with: nil)
    let controller = UIActivityViewController(activityItems: payload, applicationActivities: nil)
    controller.excludedActivityTypes = UIActivity.standardExcludedTypes
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
