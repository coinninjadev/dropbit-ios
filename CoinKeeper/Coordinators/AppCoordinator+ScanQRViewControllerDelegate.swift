//
//  AppCoordinator+ScanQRViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension AppCoordinator: ScanQRViewControllerDelegate {

  private var exchangeRates: ExchangeRates {
    return self.currencyController.exchangeRates
  }

  private var fiatCurrency: CurrencyCode {
    return self.currencyController.fiatCurrency
  }

  func viewControllerDidScan(_ viewController: UIViewController, qrCode: QRCode, fallbackViewModel: SendPaymentViewModel?) {
    if let paymentRequestURL = qrCode.paymentRequestURL {
      self.resolveMerchantPaymentRequest(withURL: paymentRequestURL) { result in
        switch result {
        case .success(let response):
          guard let fetchedModel = SendPaymentViewModel(response: response,
                                                        exchangeRates: self.exchangeRates,
                                                        fiatCurrency: self.fiatCurrency,
                                                        delegate: nil)
            else { return }
          self.showSendPaymentViewController(withViewModel: fetchedModel, dismissing: viewController, completion: nil)

        case .failure(let paymentRequestError):
          let errorMessage = paymentRequestError.errorDescription ?? self.defaultPaymentErrorMessage
          let errorAlert = self.alertManager.defaultAlert(withTitle: self.paymentErrorTitle, description: errorMessage)
          let currencyPair = CurrencyPair(btcPrimaryWith: self.currencyController)
          let swappableVM = CurrencySwappableEditAmountViewModel(exchangeRates: self.exchangeRates,
                                                                 primaryAmount: .zero,
                                                                 currencyPair: currencyPair)
          let viewModel = SendPaymentViewModel(editAmountViewModel: swappableVM)

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
    let shouldUseFallback = (qrCode.btcAmount ?? .zero) == .zero
    var qrCodeToUse = qrCode
    if shouldUseFallback {
      let fallbackConverter = fallbackViewModel?.generateCurrencyConverter()
      let fallbackAmount = fallbackConverter?.btcAmount ?? .zero
      let fallbackQRCode = qrCode.copy(withBTCAmount: fallbackAmount)
      qrCodeToUse = fallbackQRCode
    }

    let viewModel = SendPaymentViewModel(qrCode: qrCodeToUse,
                                         exchangeRates: self.exchangeRates,
                                         currencyPair: self.currencyController.currencyPair,
                                         delegate: nil)

    let sendPaymentVC = SendPaymentViewController.newInstance(delegate: self, viewModel: viewModel)
    sendPaymentVC.alertManager = self.alertManager
    return sendPaymentVC
  }

  func showSendPaymentViewController(withViewModel viewModel: SendPaymentViewModel,
                                     dismissing viewController: UIViewController,
                                     completion: ((SendPaymentViewController) -> Void)?) {
    let sendPaymentViewController = SendPaymentViewController.newInstance(delegate: self, viewModel: viewModel)
    sendPaymentViewController.alertManager = alertManager

    viewController.dismiss(animated: true) { [weak self] in
      self?.navigationController.present(sendPaymentViewController, animated: true) {
        completion?(sendPaymentViewController)
      }
    }
  }

  func showScanViewController(fallbackBTCAmount: NSDecimalNumber, primaryCurrency: CurrencyCode) {
    let scanViewController = ScanQRViewController.makeFromStoryboard()
    let currencyPair = CurrencyPair(btcPrimaryWith: self.currencyController)
    let swappableVM = CurrencySwappableEditAmountViewModel(exchangeRates: self.exchangeRates,
                                                           primaryAmount: fallbackBTCAmount,
                                                           currencyPair: currencyPair)
    scanViewController.fallbackPaymentViewModel = SendPaymentViewModel(editAmountViewModel: swappableVM)

    assignCoordinationDelegate(to: scanViewController)
    scanViewController.modalPresentationStyle = .formSheet
    navigationController.present(scanViewController, animated: true, completion: nil)
  }

}
