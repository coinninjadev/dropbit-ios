//
//  MockDataGenerator.swift
//  DropBitTests
//
//  Created by Ben Winters on 8/27/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

struct MockOnChainDataGenerator {

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
                                btcAddress: MockSummaryCellVM.mockValidBitcoinAddress())
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
       isLightningTransfer: Bool = false,
       btcAddress: String? = nil) {

    let amtDetails = MockSummaryCellVM.testAmountDetails(cents: fiatAmount)

    super.init(walletTxType: .onChain,
               direction: direction,
               status: status,
               isLightningTransfer: isLightningTransfer,
               btcAddress: btcAddress,
               lightningInvoice: nil,
               selectedCurrency: .fiat,
               amountDetails: amtDetails,
               counterpartyConfig: counterparty,
               memo: memo)
  }
}
