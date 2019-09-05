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

protocol PaymentBuildingDelegate {
  func viewController(
    _ viewController: UIViewController,
    sendingMax txData: CNBTransactionData,
    to address: String,
    inputs: SendingDelegateInputs)

  func configureOutgoingTransactionData(with dto: OutgoingTransactionData,
                                        address: String?,
                                        inputs: SendingDelegateInputs) -> OutgoingTransactionData
  
  func viewControllerRequestedShowFeeTooExpensiveAlert(_ viewController: UIViewController)
}

extension AppCoordinator: PaymentBuildingDelegate {

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
    copy.dropBitType = inputs.contact?.dropBitType ?? .none
    if let innerContact = inputs.contact {
      copy.displayName = innerContact.displayName ?? ""
      copy.displayIdentity = innerContact.displayIdentity
      copy.identityHash = innerContact.identityHash
    }
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
