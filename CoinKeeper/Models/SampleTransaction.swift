//
//  SampleTransaction.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

struct SampleCounterpartyName {
  var name: String?

  var description: String? {
    return name
  }
}

struct SampleCounterpartyAddress {
  var addressId: String
}

struct SamplePhoneNumber {
  var countryCode: Int16
  var number: Int
  var phoneNumberHash: String
  var status: String
  var counterpartyName: SampleCounterpartyName
}

struct SampleInvitation {
  var name: String
  var phoneNumber: GlobalPhoneNumber?
  var btcAmount: Int
  var fees: Int
  var sentDate: Date?
  var status: InvitationStatus
}

struct SampleAddressTransactionSummary {
  var txid: String
  var address: String
  var addressReceived: Int
  var addressSent: Int

  let isChangeAddress = false

  init(sampleTransaction sampleTx: SampleTransaction) {
    self.txid = sampleTx.id
    self.address = sampleTx.walletAddress
    self.addressReceived = (sampleTx.walletReceived ?? .zero).asFractionalUnits(of: .BTC)
    self.addressSent = (sampleTx.walletSent ?? .zero).asFractionalUnits(of: .BTC)
  }
}

class SampleTransaction: TransactionHistoryDetailCellViewModel {

  var id: String
  var walletAddress: String

  init(
    netWalletAmount: NSDecimalNumber?,
    id: String,
    btcReceived: NSDecimalNumber?,
    isIncoming: Bool,
    walletAddress: String,
    confirmations: Int,
    date: Date?,
    counterpartyAddress: SampleCounterpartyAddress?,
    phoneNumber: SamplePhoneNumber?,
    invitation: SampleInvitation?
    ) {
    self.id = id
    self.walletAddress = walletAddress
    self.counterpartyAddress = counterpartyAddress
    self.phoneNumber = phoneNumber
    self.invitation = invitation

    super.init()

    self.netWalletAmount = netWalletAmount
    self.btcReceived = btcReceived
    self.isIncoming = isIncoming
    self.confirmations = confirmations
    self.date = date
    self.networkFee = NSDecimalNumber(integerAmount: 300, currency: .BTC)
    self.counterpartyDescription = phoneNumber?.counterpartyName.description ?? ""
    let sentAmount = btcSent ?? .zero
    self.sentAmountAtCurrentConverter = CurrencyConverter(rates: sampleRates, fromAmount: sentAmount, fromCurrency: .BTC, toCurrency: .USD)
    self.invitationStatus = invitation?.status
    self.receiverAddress = isIncoming ? walletAddress : counterpartyAddress?.addressId
    self.isCancellable = (invitation?.status ?? .completed) != .completed
  }
  var counterpartyAddress: SampleCounterpartyAddress?
  var phoneNumber: SamplePhoneNumber?
  var invitation: SampleInvitation?

  let sampleRates: ExchangeRates = [.BTC: 1, .USD: 7000]

  var walletReceived: NSDecimalNumber? {
    return isIncoming ? btcReceived : .zero
  }

  var btcSent: NSDecimalNumber? {
    return self.networkFee.flatMap { btcReceived?.adding($0) }
  }

  var walletSent: NSDecimalNumber? {
    return isIncoming ? .zero : btcSent
  }

  static let sampleWalletAddress = "3NNE2SY73JkrupbWKu6iVCsGjrcNKXH4hR"

  static var history: [SampleTransaction] = {
    let id1 = "54b224e4eef004e66bdac46f13a80db56687262f0923be02ad0e9469496126ef"
    let btcReceived1 = NSDecimalNumber(integerAmount: 100_000, currency: .BTC)
    let sampleCounterpartyAddress1 = SampleCounterpartyAddress(addressId: "13r1jyivitShUiv9FJvjLH7Nh1ZZptumwE")
    let sampleCounterpartyName1 = SampleCounterpartyName(name: nil)
    let samplePhone1 = SamplePhoneNumber(
      countryCode: 1,
      number: 3305551212,
      phoneNumberHash: "",
      status: "",
      counterpartyName: sampleCounterpartyName1)
    let sampleTx1 = SampleTransaction(
      netWalletAmount: nil,
      id: id1,
      btcReceived: btcReceived1,
      isIncoming: false,
      walletAddress: sampleWalletAddress,
      confirmations: 0,
      date: Date.new(2017, 10, 6, time: 12, 20),
      counterpartyAddress: sampleCounterpartyAddress1,
      phoneNumber: samplePhone1,
      invitation: nil)

    let id2 = "497d8500b9c986f89e79ecbe8c353564dd202ae882c037465bde57668481aa43"
    let btcReceived2 = NSDecimalNumber(integerAmount: 100_000, currency: .BTC)
    let sampleCounterpartyAddress2 = SampleCounterpartyAddress(addressId: "13r1jyivitShUiv9FJvjLH7Nh1ZZptumwD")
    let sampleCounterpartyName2 = SampleCounterpartyName(name: "Larry Harmon")
    let samplePhone2 = SamplePhoneNumber(
      countryCode: 1,
      number: 3305551212,
      phoneNumberHash: "",
      status: "", counterpartyName: sampleCounterpartyName1)
    let sampleTx2 = SampleTransaction(
      netWalletAmount: nil,
      id: id2,
      btcReceived: btcReceived2,
      isIncoming: true,
      walletAddress: sampleWalletAddress,
      confirmations: 4,
      date: Date.new(2017, 10, 5, time: 12, 20),
      counterpartyAddress: sampleCounterpartyAddress2,
      phoneNumber: samplePhone2,
      invitation: nil)

    let samplePhone3 = SamplePhoneNumber(
      countryCode: 1,
      number: 3305551212,
      phoneNumberHash: "",
      status: "",
      counterpartyName: sampleCounterpartyName1)
    let sampleInvitation3 = SampleInvitation(
      name: "Gary Harmon",
      phoneNumber: nil,
      btcAmount: 50_000,
      fees: 300,
      sentDate: Date.new(2017, 10, 4, time: 12, 20),
      status: .requestSent)
    let sampleTx3 = SampleTransaction(
      netWalletAmount: nil,
      id: "",
      btcReceived: nil,
      isIncoming: false,
      walletAddress: sampleWalletAddress,
      confirmations: 0,
      date: Date.new(2017, 10, 4, time: 12, 20),
      counterpartyAddress: nil,
      phoneNumber: samplePhone3,
      invitation: sampleInvitation3)

    let id4 = "e431a76bdc8e3b66cf42ed79d21b7c1644ceb1a35e0c4d90a95c43ce2420b864"
    let btcReceived4 = NSDecimalNumber(integerAmount: 100_000, currency: .BTC)
    let sampleCounterpartyAddress4 = SampleCounterpartyAddress(addressId: "13r1jyivitShUiv9FJvjLH7Nh1ZZptumwC")
    let sampleCounterpartyName4 = SampleCounterpartyName(name: "Tom Martindale")
    let samplePhoneNumber4 = SamplePhoneNumber(
      countryCode: 1,
      number: 12345,
      phoneNumberHash: "",
      status: "",
      counterpartyName: sampleCounterpartyName4)
    let sampleTx4 = SampleTransaction(
      netWalletAmount: nil,
      id: id4,
      btcReceived: btcReceived4,
      isIncoming: false,
      walletAddress: sampleWalletAddress,
      confirmations: 1,
      date: Date.new(2017, 10, 3, time: 12, 20),
      counterpartyAddress: sampleCounterpartyAddress4,
      phoneNumber: samplePhoneNumber4,
      invitation: nil)

    let id5 = "c4af4debd9a9f0f910dd13b0309e02d5306228176e90672c5f04ba3f03ce8070"
    let btcReceived5 = NSDecimalNumber(integerAmount: 100_000, currency: .BTC)
    let sampleCounterpartyAddress5 = SampleCounterpartyAddress(addressId: "13r1jyivitShUiv9FJvjLH7Nh1ZZptumwB")
    let sampleTx5 = SampleTransaction(
      netWalletAmount: nil,
      id: id5,
      btcReceived: btcReceived5,
      isIncoming: true,
      walletAddress: sampleWalletAddress,
      confirmations: 1,
      date: Date.new(2017, 10, 2, time: 12, 20),
      counterpartyAddress: sampleCounterpartyAddress5,
      phoneNumber: nil,
      invitation: nil)

    let id6 = "2dea274981a81471b3ec808f8063d9e9f80e9e311448a566800bbbdd6a1c9ea1"
    let btcReceived6 = NSDecimalNumber(integerAmount: 1_000_000, currency: .BTC)
    let sampleCounterpartyAddress6 = SampleCounterpartyAddress(addressId: "13r1jyivitShUiv9FJvjLH7Nh1ZZptumwA")
    let sampleCounterpartyName6 = SampleCounterpartyName(name: "Eric Bockmuller")
    let samplePhoneNumber6 = SamplePhoneNumber(
      countryCode: 1,
      number: 12345,
      phoneNumberHash: "",
      status: "",
      counterpartyName: sampleCounterpartyName6)
    let sampleTx6 = SampleTransaction(
      netWalletAmount: nil,
      id: id6,
      btcReceived: btcReceived6,
      isIncoming: true,
      walletAddress: sampleWalletAddress,
      confirmations: 7,
      date: Date.new(2017, 10, 1, time: 12, 20),
      counterpartyAddress: sampleCounterpartyAddress6,
      phoneNumber: samplePhoneNumber6,
      invitation: nil)

    return [sampleTx1, sampleTx2, sampleTx3, sampleTx4, sampleTx5, sampleTx6]
  }()
}

/// Wraps the simple case where there are only two addresses involved
typealias TransactionAddressPair = (wallet: CKMAddress, counterparty: CKMAddress?)

extension CKMTransaction {

  convenience init(sampleTx: SampleTransaction, wallet: CKMWallet, insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)

    self.txid = sampleTx.id ?? ""
    self.confirmations = sampleTx.confirmations
    self.date = sampleTx.date
    self.sortDate = sampleTx.date

    // Create transaction summary
    let sampleSummary = SampleAddressTransactionSummary(sampleTransaction: sampleTx)
    let walletAddress = CKMAddress.findOrCreate(withAddress: sampleTx.walletAddress, in: context)
    let txSummary = CKMAddressTransactionSummary(sampleSummary: sampleSummary, wallet: wallet, address: walletAddress, insertInto: context)
    self.addToAddressTransactionSummaries(txSummary)

    // Create an invitation OR a counterparty
    if let sampleInvitation = sampleTx.invitation {
      self.invitation = CKMInvitation(sampleInvitation: sampleInvitation, insertInto: context)

    } else if let sampleCounterpartyAddressId = sampleTx.counterpartyAddress?.addressId {
      let counterpartyAddress = CKMCounterpartyAddress(address: sampleCounterpartyAddressId, insertInto: context)
      self.counterpartyAddress = counterpartyAddress
    }
  }

}

extension CKMInvitation {
  convenience init(sampleInvitation: SampleInvitation, insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)

    self.counterpartyName = sampleInvitation.name
    self.btcAmount = sampleInvitation.btcAmount
    self.sentDate = sampleInvitation.sentDate
    self.status = sampleInvitation.status
    self.setFlatFee(to: sampleInvitation.fees)

    if let phoneNumber = sampleInvitation.phoneNumber, let inputs = ManagedPhoneNumberInputs(phoneNumber: phoneNumber) {
      self.counterpartyPhoneNumber = CKMPhoneNumber.findOrCreate(withInputs: inputs, phoneNumberHash: "", in: context)
    }
  }
}

extension CKMAddressTransactionSummary {
  convenience init(sampleSummary: SampleAddressTransactionSummary,
                   wallet: CKMWallet,
                   address: CKMAddress,
                   insertInto context: NSManagedObjectContext) {

    self.init(insertInto: context)

    self.txid = sampleSummary.txid
    self.sent = sampleSummary.addressSent
    self.received = sampleSummary.addressReceived
    self.isChangeAddress = sampleSummary.isChangeAddress
    self.wallet = wallet
    self.address = address
  }
}
