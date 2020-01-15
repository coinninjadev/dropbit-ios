//
//  AppCoordinator+PaymentBuildingDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/5/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import Foundation
import PromiseKit
import Cnlib

struct PaymentData {
  var broadcastData: CNBCnlibTransactionData
  var outgoingData: OutgoingTransactionData
}

enum SelectedBTCAmount {
  case specific(NSDecimalNumber)
  case max
}

protocol PaymentBuildingDelegate: CurrencyValueDataSourceType {

  func transactionDataSendingMaxFunds(toAddress destinationAddress: String) -> Promise<CNBCnlibTransactionData>

  func configureOutgoingTransactionData(with dto: OutgoingTransactionData,
                                        address: String?,
                                        inputs: SendingDelegateInputs) -> OutgoingTransactionData

  func buildLoadLightningPaymentData(selectedAmount: SelectedBTCAmount,
                                     exchangeRates: ExchangeRates,
                                     in context: NSManagedObjectContext) -> Promise<PaymentData>

}

extension AppCoordinator: PaymentBuildingDelegate {

  func transactionDataSendingMaxFunds(toAddress destinationAddress: String) -> Promise<CNBCnlibTransactionData> {
    return latestFees()
      .compactMap { self.usableFeeRate(from: $0) }
      .then { feeRate -> Promise<CNBCnlibTransactionData> in
        guard let wmgr = self.walletManager else { return Promise(error: DBTError.Persistence.noManagedWallet) }
        return wmgr.transactionDataSendingMax(to: destinationAddress, withFeeRate: feeRate)
    }
  }

  func buildLoadLightningPaymentData(selectedAmount: SelectedBTCAmount,
                                     exchangeRates: ExchangeRates,
                                     in context: NSManagedObjectContext) -> Promise<PaymentData> {
    let wallet = CKMWallet.findOrCreate(in: context)
    let lightningAccount = self.persistenceManager.brokers.lightning.getAccount(forWallet: wallet, in: context)
    return networkManager.latestFees().compactMap { FeeRates(fees: $0) }
      .then { (feeRates: FeeRates) -> Promise<PaymentData> in
        do {
          try BitcoinAddressValidator().validate(value: lightningAccount.address)
          log.info("Lightning load address successfully validated.")
        } catch {
          log.error(error, message: "Lightning load address failed validation. Address: \(lightningAccount.address)")
          return Promise(error: error)
        }
        let feeRate: Double = feeRates.low
        let maybePaymentData = self.buildNonReplaceableTransactionData(selectedAmount: selectedAmount,
                                                                       address: lightningAccount.address,
                                                                       exchangeRates: exchangeRates,
                                                                       feeRate: feeRate)
        if let paymentData = maybePaymentData {
          do {
            try BitcoinAddressValidator().validate(value: paymentData.broadcastData.paymentAddress)
            log.info("Lightning load address successfully validated after creating transaction data.")
            return Promise.value(paymentData)
          } catch {
            log.error(error, message: "Lightning load address failed validation. Address: \(lightningAccount.address)")
            return Promise(error: error)
          }
        } else {
          return Promise(error: DBTError.TransactionData.insufficientFunds)
        }
    }
  }

  private func buildNonReplaceableTransactionData(
    selectedAmount: SelectedBTCAmount,
    address: String,
    exchangeRates: ExchangeRates,
    feeRate: Double) -> PaymentData? {
    var outgoingTransactionData = OutgoingTransactionData.emptyInstance()
    let sharedPayload = SharedPayloadDTO.emptyInstance()
    let rbfOption = RBFOption.mustNotBeRBF
    let inputs = SendingDelegateInputs(
      primaryCurrency: .BTC,
      walletTxType: .onChain,
      contact: nil,
      rates: exchangeRates,
      sharedPayload: sharedPayload,
      rbfReplaceabilityOption: rbfOption)

    outgoingTransactionData = configureOutgoingTransactionData(with: outgoingTransactionData, address: address, inputs: inputs)
    guard let broadcastData = nonReplaceableBroadcastData(for: selectedAmount, to: address, feeRate: feeRate) else { return nil }
    return PaymentData(broadcastData: broadcastData, outgoingData: outgoingTransactionData)
  }

  private func nonReplaceableBroadcastData(for selectedAmount: SelectedBTCAmount, to address: String, feeRate: Double) -> CNBCnlibTransactionData? {
    switch selectedAmount {
    case .specific(let btcAmount):
      let rbfOption = RBFOption.mustNotBeRBF
      return walletManager?.failableTransactionData(forPayment: btcAmount, to: address, withFeeRate: feeRate, rbfOption: rbfOption)
    case .max:
      return walletManager?.failableTransactionDataSendingMax(to: address, withFeeRate: feeRate)
    }
  }

  func configureOutgoingTransactionData(with dto: OutgoingTransactionData,
                                        address: String?,
                                        inputs: SendingDelegateInputs) -> OutgoingTransactionData {
    guard let wmgr = self.walletManager else { return dto }

    var copy = dto
    copy.receiver = inputs.contact?.asDropBitReceiver
    address.map { copy.destinationAddress = $0 }
    copy.sharedPayloadDTO = inputs.sharedPayload

    let context = persistenceManager.createBackgroundContext()
    context.performAndWait {
      let ads = wmgr.createAddressDataSource()
      if (try? ads.checkAddressExists(for: copy.destinationAddress, in: context)) != nil {
        copy.sentToSelf = true
      }
    }

    return copy
  }

}
