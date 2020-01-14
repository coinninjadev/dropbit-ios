//
//  AppCoordinator+TransactionHistoryDetailsViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 7/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

extension AppCoordinator: TransactionHistoryDetailsViewControllerDelegate {
  func viewController(_ viewController: TransactionHistoryDetailsViewController,
                      didCancelInvitationWithID invitationID: String,
                      at indexPath: IndexPath) {
    let neverMindAction = AlertActionConfiguration(title: "Never mind", style: .cancel, action: nil)
    let cancelInvitationAction = AlertActionConfiguration(title: "Cancel DropBit", style: .default, action: { [weak self] in
      guard let strongSelf = self,
        let walletWorker = strongSelf.workerFactory().createWalletAddressDataWorker(delegate: strongSelf)
        else { return }
      let context = strongSelf.persistenceManager.createBackgroundContext()
      context.performAndWait {
        walletWorker.cancelInvitation(withID: invitationID, in: context)
          .done(in: context) {
            context.performAndWait {
              try? context.saveRecursively()
            }

            strongSelf.analyticsManager.track(event: .cancelDropbitPressed, with: nil)

            DispatchQueue.main.async {
              // Manual reloading is necessary because the frc will not automatically reload
              // since the status change is made to the related invitation and not the transaction.
              viewController.collectionView.reloadItems(at: [indexPath])
            }
          }
          .catchDisplayable { error in
            strongSelf.alertManager.showError(message: "Failed to cancel invitation.\nError details: \(error.displayMessage)", forDuration: 5.0)
        }
      }
    })

    let alert = alertManager.alert(withTitle: "Cancel DropBit",
                                   description: "Are you sure you want to cancel this DropBit invitation?",
                                   image: nil,
                                   style: .alert,
                                   actionConfigs: [neverMindAction, cancelInvitationAction])
    viewController.present(alert, animated: true, completion: nil)
  }

}
