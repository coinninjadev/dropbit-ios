//
//  TransactionShareable.swift
//  DropBit
//
//  Created by Ben Winters on 6/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol TransactionShareable: AnyObject {
  /// Pass nil for the transaction to share the latest transaction
  func viewControllerRequestedShareTransactionOnTwitter(_ viewController: UIViewController,
                                                        walletTxType: WalletTransactionType,
                                                        transaction: TransactionDetailCellActionable?,
                                                        shouldDismiss: Bool)
}
