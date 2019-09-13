//
//  AppCoordinator+PaymentBuildingDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/5/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit
import CNBitcoinKit

struct PaymentData {
  var broadcastData: CNBTransactionData
  var outgoingData: OutgoingTransactionData
}

protocol PaymentBuildingDelegate {
  func sendMaxFundsTo(address destinationAddress: String,
                      feeRate: Double) -> Promise<CNBTransactionData>

  func configureOutgoingTransactionData(with dto: OutgoingTransactionData,
                                        address: String?,
                                        inputs: SendingDelegateInputs) -> OutgoingTransactionData
  func buildTransactionData(
    btcAmount: NSDecimalNumber,
    address: String,
    exchangeRates: ExchangeRates) -> PaymentData?
}

extension AppCoordinator: PaymentBuildingDelegate {

  func buildTransactionData(
    btcAmount: NSDecimalNumber,
    address: String,
    exchangeRates: ExchangeRates) -> PaymentData? {
    var outgoingTransactionData = OutgoingTransactionData.emptyInstance()
    let sharedPayload = SharedPayloadDTO.emptyInstance()
    let inputs = SendingDelegateInputs(primaryCurrency: .BTC, walletTxType: .onChain, contact: nil,
                                       rates: exchangeRates, sharedPayload: sharedPayload)

    outgoingTransactionData = configureOutgoingTransactionData(with: outgoingTransactionData, address: address, inputs: inputs)
    guard let bitcoinKitTransactionData = walletManager?.failableTransactionData(forPayment: btcAmount,
                                                                                 to: address, withFeeRate: 0.0) else { return nil }

    return PaymentData(broadcastData: bitcoinKitTransactionData, outgoingData: outgoingTransactionData)
  }

  func sendMaxFundsTo(address destinationAddress: String,
                      feeRate: Double) -> Promise<CNBTransactionData> {
    guard let wmgr = walletManager else { return Promise(error: CKPersistenceError.noManagedWallet) }
    let data = wmgr.transactionDataSendingMax(to: destinationAddress, withFeeRate: feeRate)
    return data
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
      if wmgr.createAddressDataSource().checkAddressExists(for: copy.destinationAddress, in: context) != nil {
        copy.sentToSelf = true
      }
    }

    return copy
  }

}
