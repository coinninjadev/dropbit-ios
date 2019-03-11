//
//  AppCoordinator+TransactionPopoverDetailsViewControllerDelegate.swift
//  DropBit
//
//  Created by Mitch on 12/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: TransactionPopoverDetailsViewControllerDelegate {
  func viewControllerDidTapTransactionDetailsButton(with url: URL) {
    openURL(url, completionHandler: nil)
  }

  func viewControllerDidTapQuestionMarkButton(with url: URL) {
    openURL(url, completionHandler: nil)
  }

  func viewControllerDidTapShareTransactionButton() {
    analyticsManager.track(event: .shareTransactionPressed, with: nil)
  }
}
