//
//  AppCoordinator+ScanQRViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: ScanQRViewControllerDelegate {

  func viewControllerDidScan(_ viewController: UIViewController, qrCode: QRCode, fallbackViewModel: SendPaymentViewModel?) {
    if let paymentRequestURL = qrCode.paymentRequestURL {
      self.resolveMerchantPaymentRequest(withURL: paymentRequestURL) { result in
        switch result {
        case .success(let response):
          guard let fetchedModel = SendPaymentViewModel(response: response) else { return }
          self.showSendPaymentViewController(withViewModel: fetchedModel, dismissing: viewController, completion: nil)

        case .failure(let paymentRequestError):
          let errorMessage = paymentRequestError.errorDescription ?? self.defaultPaymentErrorMessage
          let errorAlert = self.alertManager.defaultAlert(withTitle: self.paymentErrorTitle, description: errorMessage)
          let viewModel = SendPaymentViewModel(btcAmount: .zero, primaryCurrency: .BTC)

          self.showSendPaymentViewController(withViewModel: viewModel, dismissing: viewController) { sendPaymentViewController in
            sendPaymentViewController.present(errorAlert, animated: true, completion: nil)
          }
        }
      }

    } else {
      let sendPaymentViewController = self.createSendPaymentViewController(forQRCode: qrCode, fallbackViewModel: fallbackViewModel)
      viewController.dismiss(animated: true) { [weak self] in
        self?.navigationController.present(sendPaymentViewController, animated: true)
      }
    }
  }

  private func createSendPaymentViewController(forQRCode qrCode: QRCode, fallbackViewModel: SendPaymentViewModel?) -> SendPaymentViewController {
    let sendPaymentViewController = SendPaymentViewController.makeFromStoryboard()
    assignCoordinationDelegate(to: sendPaymentViewController)
    sendPaymentViewController.alertManager = self.alertManager

    let primaryCurrency = fallbackViewModel?.primaryCurrency ?? .BTC
    let shouldUseFallback = (qrCode.btcAmount ?? .zero) == .zero

    if shouldUseFallback {
      let fallbackAmount = fallbackViewModel?.btcAmount ?? .zero
      let fallbackQRCode = qrCode.copy(withBTCAmount: fallbackAmount)
      sendPaymentViewController.viewModel = SendPaymentViewModel(qrCode: fallbackQRCode, primaryCurrency: primaryCurrency)
    } else {
      sendPaymentViewController.viewModel = SendPaymentViewModel(qrCode: qrCode, primaryCurrency: .BTC)
    }
    sendPaymentViewController.viewModel.updatePrimaryCurrency(to: currencyController.selectedCurrency)

    return sendPaymentViewController
  }

  func showSendPaymentViewController(withViewModel viewModel: SendPaymentViewModel?,
                                     dismissing viewController: UIViewController,
                                     completion: ((SendPaymentViewController) -> Void)?) {
    let sendPaymentViewController = SendPaymentViewController.makeFromStoryboard()
    self.assignCoordinationDelegate(to: sendPaymentViewController)
    sendPaymentViewController.alertManager = alertManager
    if let vm = viewModel {
      sendPaymentViewController.viewModel = vm
    }
    sendPaymentViewController.viewModel.updatePrimaryCurrency(to: currencyController.selectedCurrency)

    viewController.dismiss(animated: true) { [weak self] in
      self?.navigationController.present(sendPaymentViewController, animated: true) {
        completion?(sendPaymentViewController)
      }
    }
  }

}
