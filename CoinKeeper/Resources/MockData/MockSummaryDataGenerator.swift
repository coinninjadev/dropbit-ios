//
//  MockSummaryDataGenerator.swift
//  DropBit
//
//  Created by Ben Winters on 9/26/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct MockOnChainSummaryDataGenerator {

  var mayUtilities: MockSummaryCellVM {
    let counterparty = TransactionCellCounterpartyConfig(displayName: "Adam Wolf")
    return MockOnChainSummaryVM(direction: .out,
                                fiatAmount: 500,
                                counterparty: counterparty,
                                memo: "May utilities ⚡️💧⛽️")
  }

  var lightningWithdraw: MockSummaryCellVM {
    return MockOnChainSummaryVM(direction: .in,
                                fiatAmount: 5000,
                                counterparty: nil,
                                memo: nil,
                                isLightningTransfer: true)
  }

  var coffee: MockSummaryCellVM {
    let twitter = MockSummaryCellVM.mockTwitterConfig()
    let counterparty = TransactionCellCounterpartyConfig(twitterConfig: twitter)
    return MockOnChainSummaryVM(direction: .out,
                                fiatAmount: 800,
                                counterparty: counterparty,
                                memo: "Coffee ☕️")
  }

  var drinksAndFood: MockSummaryCellVM {
    let counterparty = TransactionCellCounterpartyConfig(displayName: "Adam Wolf")
    return MockOnChainSummaryVM(direction: .out,
                                fiatAmount: 3500,
                                counterparty: counterparty,
                                memo: "Drinks and Food")
  }

  var loadLightning: MockSummaryCellVM {
    return MockOnChainSummaryVM(direction: .out,
                                fiatAmount: 5000,
                                counterparty: nil,
                                memo: nil,
                                isLightningTransfer: true)
  }

  var genericIncoming: MockSummaryCellVM {
    return MockOnChainSummaryVM(direction: .in,
                                fiatAmount: 800,
                                counterparty: nil,
                                memo: "Testing",
                                receiverAddress: MockSummaryCellVM.mockValidBitcoinAddress())
  }

  var canceledPhoneInvite: MockSummaryCellVM {
    let counterparty = TransactionCellCounterpartyConfig(displayPhoneNumber: "(123) 456-7890")
    return MockOnChainSummaryVM(direction: .out,
                                fiatAmount: 800,
                                counterparty: counterparty,
                                memo: "Chipotle 🌯",
                                status: .canceled)
  }

}

class MockOnChainSummaryVM: MockTransactionSummaryCellViewModel {

  init(direction: TransactionDirection,
       fiatAmount: Int,
       counterparty: TransactionCellCounterpartyConfig?,
       memo: String?,
       status: TransactionStatus = .completed,
       isSentToSelf: Bool = false,
       isLightningTransfer: Bool = false,
       receiverAddress: String? = nil) {

    let amtFactory = MockSummaryCellVM.testAmountFactory(cents: fiatAmount)

    super.init(walletTxType: .onChain,
               direction: direction,
               status: status,
               isSentToSelf: isSentToSelf,
               receiverAddress: receiverAddress,
               lightningInvoice: nil,
               isLightningTransfer: isLightningTransfer,
               isLightningUpgrade: false,
               selectedCurrency: .fiat,
               amountFactory: amtFactory,
               counterpartyConfig: counterparty,
               memo: memo)
  }
}

struct MockLightningSummaryDataGenerator {

  var pendingInvoice: MockSummaryCellVM {
    let counterparty = TransactionCellCounterpartyConfig(displayName: "Adam Wolf")
    return MockLightningSummaryVM(direction: .in,
                                  sats: 120_000,
                                  counterparty: counterparty,
                                  memo: "Chipotle 🌯",
                                  status: .pending)
  }

  var lightningWithdraw: MockSummaryCellVM {
    return MockLightningSummaryVM(direction: .out,
                                  sats: 5_000_000,
                                  counterparty: nil,
                                  memo: nil,
                                  isLightningTransfer: true)
  }

  var coffee: MockSummaryCellVM {
    let twitter = MockSummaryCellVM.mockTwitterConfig()
    let counterparty = TransactionCellCounterpartyConfig(twitterConfig: twitter)
    return MockLightningSummaryVM(direction: .out,
                                  sats: 80_000,
                                  counterparty: counterparty,
                                  memo: "Coffee ☕️")
  }

  var expiredInvoice: MockSummaryCellVM {
    let invoice = MockSummaryCellVM.mockLightningInvoice()
    return MockLightningSummaryVM(direction: .in,
                                  sats: 35_000_000,
                                  counterparty: nil,
                                  memo: "Drinks and Food",
                                  status: .expired,
                                  lightningInvoice: invoice)
  }

  var loadLightning: MockSummaryCellVM {
    return MockLightningSummaryVM(direction: .in,
                                  sats: 5_000_000,
                                  counterparty: nil,
                                  memo: nil,
                                  isLightningTransfer: true)
  }

  var paidInvoice: MockSummaryCellVM {
    let invoice = MockSummaryCellVM.mockLightningInvoice()
    return MockLightningSummaryVM(direction: .out,
                                  sats: 50_000,
                                  counterparty: nil,
                                  memo: "Parking",
                                  lightningInvoice: invoice)
  }

  var expiredPhoneInvite: MockSummaryCellVM {
    let counterparty = TransactionCellCounterpartyConfig(displayPhoneNumber: "(123) 456-7890")
    return MockLightningSummaryVM(direction: .out,
                                  sats: 35_000_000,
                                  counterparty: counterparty,
                                  memo: "Chipotle 🌯",
                                  status: .expired)
  }

}

class MockLightningSummaryVM: MockTransactionSummaryCellViewModel {

  init(direction: TransactionDirection,
       sats: Int,
       counterparty: TransactionCellCounterpartyConfig?,
       memo: String?,
       status: TransactionStatus = .completed,
       isLightningTransfer: Bool = false,
       lightningInvoice: String? = nil) {

    let amtFactory = MockSummaryCellVM.testAmountFactory(sats: sats)

    super.init(walletTxType: .lightning,
               direction: direction,
               status: status,
               isSentToSelf: false,
               receiverAddress: nil,
               lightningInvoice: lightningInvoice,
               isLightningTransfer: isLightningTransfer,
               isLightningUpgrade: false,
               selectedCurrency: .fiat,
               amountFactory: amtFactory,
               counterpartyConfig: counterparty,
               memo: memo)
  }
}
