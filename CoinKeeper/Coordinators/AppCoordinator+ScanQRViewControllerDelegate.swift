//
//  AppCoordinator+ScanQRViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 4/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import Cnlib
import PromiseKit

extension AppCoordinator: ScanQRViewControllerDelegate {
  func viewControllerDidScan(_ viewController: ScanQRViewController,
                             possibleDestinations: [String],
                             fallbackViewModel: SendPaymentViewModel?,
                             completion: @escaping CKCompletion) {
    guard let walletManager = walletManager else { return }
    let lightningQRCodes = possibleDestinations.compactMap { LightningURL(string: $0) }
    let bitcoinQRCodes = possibleDestinations.compactMap { OnChainQRCode(string: $0) }
    let wifPrivateKeys = possibleDestinations.compactMap { WIFPrivateKey(wallet: walletManager.wallet, string: $0) }
    guard lightningQRCodes.isNotEmpty || bitcoinQRCodes.isNotEmpty || wifPrivateKeys.isNotEmpty else {
      viewControllerHadScanFailure(viewController, error: .noBitcoinQRCodes)
      return
    }

    if let wifPrivateKey = wifPrivateKeys.first {
      viewControllerDidScan(viewController, privateKey: wifPrivateKey, completion: completion)
    } else if let lightningQRCode = lightningQRCodes.first, viewController.currentLockStatus != .locked {
      viewControllerDidScan(viewController,
                            lightningInvoice: lightningQRCode.invoice,
                            completion: completion)
    } else if let bitcoinQRCode = bitcoinQRCodes.first {
      viewControllerDidScan(viewController, bitcoinQRCode: bitcoinQRCode,
                            fallbackViewModel: fallbackViewModel, completion: completion)
    }
  }

  private func viewControllerDidScan(_ viewController: ScanQRViewController,
                                     privateKey: WIFPrivateKey,
                                     completion: @escaping CKCompletion) {
    viewController.dismiss(animated: true, completion: {
      self.alertManager.showActivityHUD(withStatus: "Searching blockchain for balance...")
      self.networkManager.fetchTransactionSummaries(for: privateKey.addresses, afterDate: nil)
        .then { (responses: [AddressTransactionSummaryResponse]) -> Promise<WIFPrivateKey> in
          let relevantResponse = self.findRelevantFunds(for: responses)
          if let response = relevantResponse {
            privateKey.key.previousOutputInfo = CNBCnlibNewPreviousOutputInfo(response.address, response.txid, 0, response.balance)
          } else {
            privateKey.key.previousOutputInfo = nil
          }

          return Promise.value(privateKey)
      }.done { privateKey in
        if let txid = privateKey.key.previousOutputInfo?.txid {
          self.networkManager.fetchTransactionDetails(for: txid)
            .then { (response: TransactionResponse) -> Promise<(WIFPrivateKey, CNBCnlibTransactionData)> in
              guard let address = privateKey.key.previousOutputInfo?.selectedAddress,
                let index = response.voutResponses.filter({ $0.addresses.contains(address) }).first?.n,
                let walletManager = self.walletManager else { throw DBTError.TransactionData.noSpendableFunds }

              let context = self.persistenceManager.viewContext
              guard let receiveAddress = walletManager.createAddressDataSource()
                .nextAvailableReceiveAddress(forServerPool: false, indicesToSkip: [], in: context)?.address else {
                  throw DBTError.Wallet.unexpectedAddress
              }

              let blockHeight = self.persistenceManager.brokers.checkIn.cachedBlockHeight
              var privateKeyCopy = privateKey
              privateKeyCopy.key.previousOutputInfo?.index = index
              privateKeyCopy.isConfirmed = (response.blockHash ?? "").isEmpty ? false :
                response.blockheight.map { (blockHeight - $0) + 1 > 0 } ?? false
              let feeRate = self.persistenceManager.brokers.checkIn.fee(forType:
                self.persistenceManager.brokers.preferences.preferredTransactionFeeType)
              return walletManager.transactionDataSendingMax(fromPrivateKey: privateKeyCopy, to: receiveAddress, feeRate: feeRate)
                .then { (txData: CNBCnlibTransactionData) -> Promise<(WIFPrivateKey, CNBCnlibTransactionData)> in
                  return Promise.value((privateKeyCopy, txData))
              }
          }.done { (privateKey, txData) in
            self.showPrivateKeySweepViewController(privateKey: privateKey, data: txData)
          }.catch { error in
            self.alertManager.showErrorHUD(message: error.localizedDescription, forDuration: 2.5)
          }.finally {
            self.alertManager.hideActivityHUD(withDelay: 0.0, completion: nil)
            completion()
          }
        } else {
          self.alertManager.hideActivityHUD(withDelay: 0.0, completion: nil)
          self.showEmptyPrivateKeySweepViewController(privateKey: privateKey)
          completion()
        }
      }.catch { error in
        completion()
        self.alertManager.showErrorHUD(message: error.localizedDescription, forDuration: 2.5)
      }
    })

  }

  func viewControllerHadScanFailure(_ viewController: UIViewController, error: DBTError.AVScan) {
    alertManager.showErrorHUD(message: error.displayMessage, forDuration: 2.0)
  }

  func viewControllerDidPressPhotoButton(_ viewController: PhotoViewController) {
    permissionManager.requestPermission(for: .photos) { status in
      guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return }

      switch status {
      case .authorized:
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = viewController
        imagePickerController.sourceType = .photoLibrary
        viewController.present(imagePickerController, animated: true, completion: nil)
      default:
        break
      }
    }
  }

  func showSendPaymentViewController(withViewModel viewModel: SendPaymentViewModel,
                                     dismissing viewController: UIViewController,
                                     completion: ((SendPaymentViewController) -> Void)?) {
    DispatchQueue.main.async {
      let sendPaymentViewController = SendPaymentViewController.newInstance(delegate: self, viewModel: viewModel, alertManager: self.alertManager)

      viewController.dismiss(animated: true) { [weak self] in
        self?.navigationController.present(sendPaymentViewController, animated: true) {
          completion?(sendPaymentViewController)
        }
      }
    }
  }

  func showScanViewController(fallbackBTCAmount: NSDecimalNumber, primaryCurrency: CurrencyCode) {
    let scanViewController = ScanQRViewController.newInstance(delegate: self)
    scanViewController.modalPresentationStyle = .formSheet
    navigationController.present(scanViewController, animated: true, completion: nil)
  }

  // MARK: Private
  private var exchangeRates: ExchangeRates {
    return self.currencyController.exchangeRates
  }

  private var fiatCurrency: CurrencyCode {
    return self.currencyController.fiatCurrency
  }

  private func findRelevantFunds(for responses: [AddressTransactionSummaryResponse]) -> AddressTransactionSummaryResponse? {
    let sortedNewestToOldest = responses.sorted { (lhs, rhs) -> Bool in
      lhs.receivedTime > rhs.receivedTime
    }
    var balances: [String: Int] = [:]
    for response in sortedNewestToOldest {
      if let current = balances[response.address] {
        balances[response.address] = current + response.balance
      } else {
        balances[response.address] = response.balance
      }
    }

    var found: AddressTransactionSummaryResponse?
    for (key, value) in balances where value > 0 {
      let summary = responses
        .filter { $0.address == key }
        .filter { $0.vout > 0 }
        .first
      if let summary = summary {
        found = summary
      }
    }

    return found
  }

  private func showPrivateKeySweepViewController(privateKey: WIFPrivateKey, data: CNBCnlibTransactionData) {
    guard let topVC = navigationController.topViewController(), !(topVC is PrivateKeySweepViewController) else { return }
    let privateKeySweepViewController = PrivateKeySweepViewController.newInstance(delegate: self, privateKey: privateKey, transactionData: data)
    navigationController.topViewController()?.present(privateKeySweepViewController,
                                                      animated: true, completion: nil)
  }

  private func showEmptyPrivateKeySweepViewController(privateKey: WIFPrivateKey) {
    guard let topVC = navigationController.topViewController(), !(topVC is PrivateKeySweepViewController) else { return }
    let privateKeySweepViewController = PrivateKeySweepViewController.newInstance(emptyPrivateKey: privateKey, delegate: self)
    navigationController.topViewController()?.present(privateKeySweepViewController,
                                                      animated: true, completion: nil)
  }

  private func viewControllerWillProcess(_ viewController: UIViewController, qrCode: OnChainQRCode,
                                         walletTransactionType: WalletTransactionType, fallbackViewModel: SendPaymentViewModel?) {
    if let paymentRequestURL = qrCode.paymentRequestURL {
      self.resolveMerchantPaymentRequest(withURL: paymentRequestURL) { result in
        switch result {
        case .success(let response):
          guard let fetchedModel = SendPaymentViewModel(response: response,
                                                        walletTransactionType: walletTransactionType,
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
                                                                 walletTransactionType: walletTransactionType,
                                                                 currencyPair: currencyPair)
          let viewModel = SendPaymentViewModel(editAmountViewModel: swappableVM, walletTransactionType: walletTransactionType)

          self.showSendPaymentViewController(withViewModel: viewModel, dismissing: viewController) { sendPaymentViewController in
            sendPaymentViewController.present(errorAlert, animated: true, completion: nil)
          }
        }
      }

    } else {
      let sendPaymentViewController = self.createSendPaymentViewController(forQRCode: qrCode,
                                                                           walletTransactionType: walletTransactionType,
                                                                           fallbackViewModel: fallbackViewModel)

      viewController.dismiss(animated: true) { [weak self] in
        self?.navigationController.present(sendPaymentViewController, animated: true)
      }
    }
  }

  private func viewControllerDidScan(_ viewController: UIViewController,
                                     lightningInvoice: String,
                                     completion: @escaping CKCompletion) {
    resolveLightningInvoice(invoice: lightningInvoice) { response in
      switch response {
      case .success(let decodedInvoice):
        self.analyticsManager.track(event: .externalLightningInvoiceInput, with: nil)
        let currencyPair = CurrencyPair(btcPrimaryWith: self.currencyController)
        let viewModel = SendPaymentViewModel(encodedInvoice: lightningInvoice, decodedInvoice: decodedInvoice,
                                             exchangeRates: self.exchangeRates, currencyPair: currencyPair)
        self.showSendPaymentViewController(withViewModel: viewModel, dismissing: viewController, completion: nil)
      case .failure(let error):
        let errorAlert = self.alertManager.defaultAlert(withTitle: self.paymentErrorTitle, description: error.localizedDescription)
        viewController.present(errorAlert, animated: true, completion: nil)
      }

      DispatchQueue.main.async {
        completion()
      }
    }
  }

  private func createSendPaymentViewController(forQRCode qrCode: OnChainQRCode, walletTransactionType: WalletTransactionType,
                                               fallbackViewModel: SendPaymentViewModel?) -> SendPaymentViewController {
    let shouldUseFallback = (qrCode.btcAmount ?? .zero) == .zero
    var qrCodeToUse = qrCode
    if shouldUseFallback {
      let fallbackConverter = fallbackViewModel?.currencyConverter
      let fallbackAmount = fallbackConverter?.btcAmount ?? .zero
      let fallbackQRCode = qrCode.copy(withBTCAmount: fallbackAmount)
      qrCodeToUse = fallbackQRCode
    }

    let viewModel = SendPaymentViewModel(qrCode: qrCodeToUse,
                                         walletTransactionType: walletTransactionType,
                                         exchangeRates: self.exchangeRates,
                                         currencyPair: self.currencyController.currencyPair,
                                         delegate: nil)

    let sendPaymentVC = SendPaymentViewController.newInstance(delegate: self, viewModel: viewModel, alertManager: alertManager)
    return sendPaymentVC
  }

  private func viewControllerDidScan(_ viewController: UIViewController,
                                     bitcoinQRCode qrCode: OnChainQRCode,
                                     fallbackViewModel: SendPaymentViewModel?,
                                     completion: @escaping CKCompletion) {
    if qrCode.paymentRequestURL != nil {
      viewControllerWillProcess(viewController, qrCode: qrCode,
                                walletTransactionType: .onChain,
                                fallbackViewModel: fallbackViewModel)
    } else if let address = qrCode.address {
      do {
        let bitcoinAddressValidator = CompositeValidator<String>(validators: [StringEmptyValidator(), BitcoinAddressValidator()])
        try bitcoinAddressValidator.validate(value: address)
        viewControllerWillProcess(viewController, qrCode: qrCode,
                                  walletTransactionType: .onChain,
                                  fallbackViewModel: fallbackViewModel)
      } catch {
        viewControllerDidAttemptInvalidDestination(viewController, error: error)
      }
    }
  }

}
