//
//  AppCoordinator+PrivateKeySweepViewControllerDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 12/10/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import Cnlib
import PromiseKit

extension AppCoordinator: PrivateKeySweepViewControllerDelegate {
  func viewControllerDidConfirmTransfer(_ viewController: UIViewController,
                                        transactionData: CNBCnlibTransactionData) {
    viewController.dismiss(animated: true, completion: {
      let viewModel = PaymentSuccessFailViewModel(mode: .pending)
      let controller = SuccessFailViewController.newInstance(viewModel: viewModel, delegate: self)
      controller.action = { [weak self] in
        self?.sendTransaction(withData: transactionData, forViewController: controller)
      }
      self.navigationController.present(controller, animated: true, completion: { controller.action?() })
    })
  }

  private func sendTransaction(withData transactionData: CNBCnlibTransactionData,
                               forViewController viewController: SuccessFailViewController) {
    networkManager.broadcastTx(with: transactionData)
      .done { (txid: String) in
        let context = self.persistenceManager.createBackgroundContext()
        let outgoingTransactionData = OutgoingTransactionData(txid: txid, destinationAddress: transactionData.paymentAddress,
                                                              amount: transactionData.amount, feeAmount: transactionData.feeAmount,
                                                              sentToSelf: false, requiredFeeRate: nil, sharedPayloadDTO: nil,
                                                              sender: nil, receiver: nil)
        context.perform {
          self.persistenceManager.brokers.transaction.persistTemporaryTransaction(
            from: transactionData,
            with: outgoingTransactionData,
            txid: txid,
            invitation: nil,
            in: context,
            incomingAddress: transactionData.paymentAddress
          )

          viewController.setMode(.success)

          do {
            try context.saveRecursively()
          } catch {
            log.contextSaveError(error)
          }
        }
    }.catch { error in
      viewController.setMode(.failure)
      self.alertManager.showErrorHUD(message: error.localizedDescription, forDuration: 2.5)
    }
  }
}
