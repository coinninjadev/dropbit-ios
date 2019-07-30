//
//  TransactionHistoryDetailCellViewModelType.swift
//  DropBit
//
//  Created by Ben Winters on 7/30/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

enum TransactionDirection: String {
  case `in`, out
}

enum AccountType {
  case bitcoin, lightning
}

struct ProgressBarViewModel {
  let titles: [String]
  let stepTitles: [String]
  let width: CGFloat
  let selectedTabIndex: Int
}

struct TwitterDisplayDetails {
  let handle: String
  let avatar: UIImage
  let twitterIcon: UIImage
}

struct LightningDisplayDetails {
  let qrCode: UIImage
  let request: String
  let memo: String?
}

struct AmountDisplayDetails {
  let currencyPair: CurrencyPair
  let exchangeRates: ExchangeRates
  let primaryBTCAmount: NSDecimalNumber
  let fiatWhenCreated: NSDecimalNumber?
  let fiatWhenTransacted: NSDecimalNumber?
}

struct MemoDisplayDetails {
  let memo: String
  let isShared: Bool
  let sharingDescription: String?
  let sharingIcon: UIImage?
}

enum TransactionDetailsAction {
  case detailsURL(URL)
  case detailsPopover
  case cancel
  case remove
}

/// This interface is designed with the intention that if something is nil,
/// the corresponding view(s) should be hidden.
protocol TransactionHistoryDetailCellViewModelType {

  var isValidTransaction: Bool { get }
  var accountType: AccountType { get }

  var direction: TransactionDirection { get }
  var isLightningTransfer: Bool { get }
  var statusDescription: String { get }
  var statusTextColor: UIColor { get }
  var shouldShowStatusPill: Bool { get }
  var progressBarViewModel: ProgressBarViewModel? { get }

  var recipientDescription: String? { get }

  var bitcoinAddress: String? { get }

  var twitterDetails: TwitterDisplayDetails? { get }
  var lightningDetails: LightningDisplayDetails? { get }

  var amountDetails: AmountDisplayDetails { get }

  var canAddMemo: Bool { get }
  var memoDetails: MemoDisplayDetails? { get }

  var bitcoinAddressURL: URL? { get }
  var action: TransactionDetailsAction? { get }
  var warningMessage: String? { get }

}
