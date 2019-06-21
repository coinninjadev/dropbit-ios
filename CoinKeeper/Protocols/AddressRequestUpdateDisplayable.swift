//
//  AddressRequestUpdateDisplayable.swift
//  CoinKeeper
//
//  Created by Ben Winters on 7/29/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/**
 The properties represented here can be used to compose an alert/notification regarding
 the status of an address request, accounting for the relevant side.
 */
protocol AddressRequestUpdateDisplayable {
  var addressRequestId: String { get }
  var senderName: String? { get }
  var senderPhoneNumber: GlobalPhoneNumber? { get }
  var senderHandle: String? { get }
  var receiverName: String? { get }
  var receiverPhoneNumber: GlobalPhoneNumber? { get }
  var receiverHandle: String? { get }
  var btcAmount: Int { get }
  var fiatAmount: Int { get }
  var side: InvitationSide { get }
  var status: InvitationStatus { get }
}

extension AddressRequestUpdateDisplayable {

  var historicalCurrencyFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = CurrencyCode.USD.symbol
    formatter.maximumFractionDigits = CurrencyCode.USD.decimalPlaces
    return formatter
  }

  func senderPhoneNumber(formattedWith formatter: PhoneNumberFormatterType) -> String? {
    guard let globalNumber = senderPhoneNumber else { return nil }
    return try? formatter.string(from: globalNumber)
  }

  func receiverPhoneNumber(formattedWith formatter: PhoneNumberFormatterType) -> String? {
    guard let globalNumber = receiverPhoneNumber else { return nil }
    return try? formatter.string(from: globalNumber)
  }

  func senderDescription(phoneFormatter: PhoneNumberFormatterType) -> String {
    if let displayName = senderName ?? senderHandle {
      return displayName
    } else if let formattedNumber = senderPhoneNumber(formattedWith: phoneFormatter) {
      return formattedNumber
    } else {
      return "Someone"
    }
  }

  func receiverDescription(phoneFormatter: PhoneNumberFormatterType) -> String {
    if let displayName = receiverName ?? receiverHandle {
      return displayName
    } else if let formattedNumber = receiverPhoneNumber(formattedWith: phoneFormatter) {
      return formattedNumber
    } else {
      return "Someone"
    }
  }

  var fiatDescription: String {
    let inviteCents = self.fiatAmount
    let usdAmount = NSDecimalNumber(integerAmount: inviteCents, currency: .USD)
    return historicalCurrencyFormatter.string(from: usdAmount) ?? "-"
  }

  /// This should not be used directly. Use `btcDescription` instead.
  func formattedAmountWithoutSymbol(for number: NSDecimalNumber) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = CurrencyCode.BTC.decimalPlaces
    if number < NSDecimalNumber.one {
      formatter.maximumIntegerDigits = 0
    }
    return formatter.string(from: number) ?? ""
  }

}

/// A wrapper object for objects which don't (and shouldn't) fully conform to AddressRequestUpdateDisplayable.
struct AddressRequestUpdate: AddressRequestUpdateDisplayable {
  let phoneNumberFormatter: PhoneNumberFormatterType
  var addressRequestId: String
  var senderName: String?
  var senderPhoneNumber: GlobalPhoneNumber?
  var senderHandle: String?
  var receiverName: String?
  var receiverPhoneNumber: GlobalPhoneNumber?
  var receiverHandle: String?
  var txid: String?
  var btcAmount: Int
  var fiatAmount: Int
  var side: InvitationSide
  var status: InvitationStatus

  init?(response: WalletAddressRequestResponse, requestSide: WalletAddressRequestSide, formatter: PhoneNumberFormatterType) {
    guard let responseStatus = response.statusCase else { return nil }
    self.phoneNumberFormatter = formatter
    self.txid = response.txid
    self.addressRequestId = response.id
    self.senderPhoneNumber = response.metadata?.sender.flatMap { GlobalPhoneNumber(participant: $0) }
    self.receiverPhoneNumber = response.metadata?.receiver.flatMap { GlobalPhoneNumber(participant: $0) }
    self.btcAmount = response.metadata?.amount?.btc ?? 0
    self.fiatAmount = response.metadata?.amount?.usd ?? 0
    self.side = InvitationSide(requestSide: requestSide)
    self.status = CKMInvitation.statusToPersist(for: responseStatus, side: requestSide)
  }
}
