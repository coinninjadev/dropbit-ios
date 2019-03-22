//
//  AddressRequestUpdateDisplayable.swift
//  CoinKeeper
//
//  Created by Ben Winters on 7/29/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PhoneNumberKit

/**
 The properties represented here can be used to compose an alert/notification regarding
 the status of an address request, accounting for the relevant side.
 */
protocol AddressRequestUpdateDisplayable {
  var addressRequestId: String { get }
  var senderName: String? { get }
  var senderPhoneNumber: GlobalPhoneNumber? { get }
  var receiverName: String? { get }
  var receiverPhoneNumber: GlobalPhoneNumber? { get }
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
    if let name = senderName {
      return name
    } else if let number = senderPhoneNumber(formattedWith: phoneFormatter) {
      return number
    } else {
      return "Someone"
    }
  }

  func receiverDescription(phoneFormatter: PhoneNumberFormatterType) -> String {
    if let name = receiverName {
      return name
    } else if let number = receiverPhoneNumber(formattedWith: phoneFormatter) {
      return number
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
  var receiverName: String?
  var receiverPhoneNumber: GlobalPhoneNumber?
  var txid: String?
  var btcAmount: Int
  var fiatAmount: Int
  var side: InvitationSide
  var status: InvitationStatus

  init?(response: WalletAddressRequestResponse, requestSide: WalletAddressRequestSide, formatter: PhoneNumberFormatterType, kit: PhoneNumberKit) {
    guard let responseStatus = response.statusCase else { return nil }
    self.phoneNumberFormatter = formatter
    self.txid = response.txid
    self.addressRequestId = response.id
    self.senderPhoneNumber = response.metadata?.sender.flatMap { GlobalPhoneNumber(participant: $0, kit: kit) }
    self.receiverPhoneNumber = response.metadata?.receiver.flatMap { GlobalPhoneNumber(participant: $0, kit: kit) }
    self.btcAmount = response.metadata?.amount?.btc ?? 0
    self.fiatAmount = response.metadata?.amount?.usd ?? 0
    self.side = InvitationSide(requestSide: requestSide)
    self.status = CKMInvitation.statusToPersist(for: responseStatus, side: requestSide)
  }

  init(pendingInvitationData data: PendingInvitationData, status: InvitationStatus, formatter: PhoneNumberFormatterType) {
    self.phoneNumberFormatter = formatter
    self.addressRequestId = data.id
    self.receiverName = data.name
    self.receiverPhoneNumber = data.phoneNumber
    self.btcAmount = data.btcAmount
    self.fiatAmount = data.fiatAmount
    self.side = .sender
    self.status = status
  }

}
