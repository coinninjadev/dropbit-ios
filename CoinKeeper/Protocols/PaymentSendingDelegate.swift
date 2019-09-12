//
//  PaymentDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/5/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import CNBitcoinKit

protocol PaymentSendingDelegate {
  var alertManager: AlertManagerType { get }
  var analyticsManager: AnalyticsManagerType { get }
  var persistenceManager: PersistenceManagerType { get }
  var navigationController: UINavigationController { get }
}

protocol OnChainPaymentSendingDelegate: PaymentSendingDelegate {
  func viewControllerDidConfirmOnChainPayment(
    _ viewController: UIViewController,
    transactionData: CNBTransactionData,
    rates: ExchangeRates,
    outgoingTransactionData: OutgoingTransactionData
  )

  func viewControllerRequestedShowFeeTooExpensiveAlert(_ viewController: UIViewController)
}

protocol LightningPaymentSendingDelegate: PaymentSendingDelegate {
  func viewControllerDidConfirmLightningPayment(
    _ viewController: UIViewController,
    inputs: LightningPaymentInputs)

  func handleSuccessfulLightningPaymentVerification(with inputs: LightningPaymentInputs)
}

protocol AllPaymentSendingDelegate: LightningPaymentSendingDelegate, OnChainPaymentSendingDelegate { }

extension PaymentSendingDelegate {

  func handleFailure(error: Error?, action: CKCompletion? = nil) {
    var localizedDescription = ""
    if let txError = error as? TransactionDataError {
      localizedDescription = txError.messageDescription
    } else {
      localizedDescription = error?.localizedDescription ?? "Unknown error"
    }
    analyticsManager.track(error: .submitTransactionError, with: localizedDescription)
    let config = AlertActionConfiguration(title: "OK", style: .default, action: action)
    let configs = [config]
    let alert = alertManager.alert(
      withTitle: "",
      description: localizedDescription,
      image: nil,
      style: .alert,
      actionConfigs: configs)
    DispatchQueue.main.async { self.navigationController.topViewController()?.present(alert, animated: true) }
  }

  func presentPinEntryViewController(_ pinEntryVC: PinEntryViewController) {
    pinEntryVC.modalPresentationStyle = .overFullScreen
    navigationController.topViewController()?.present(pinEntryVC, animated: true, completion: nil)
  }

  func showShareTransactionIfAppropriate(dropBitType: OutgoingTransactionDropBitType,
                                         delegate: ShareTransactionViewControllerDelegate) {
    if case .twitter = dropBitType { return }
    if self.persistenceManager.brokers.preferences.dontShowShareTransaction {
      return
    }

    if let topVC = self.navigationController.topViewController() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        let twitterVC = ShareTransactionViewController.newInstance(delegate: delegate)
        topVC.present(twitterVC, animated: true, completion: nil)
      }
    }
  }

  func viewControllerDidRetryPayment() {
    analyticsManager.track(event: .retryFailedPayment, with: nil)
  }
}
