//
//  MockTransactionDataGenerator.swift
//  DropBitTests
//
//  Created by Ben Winters on 8/27/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum MockDataDropBitCategory: CaseIterable {
  case valid, invalid
}

struct MockDetailDataGenerator {

  let walletTxType: WalletTransactionType

  class MockDropBitVM: MockTransactionDetailValidCellViewModel {

    init(walletTxType: WalletTransactionType,
         direction: TransactionDirection,
         counterparty: TransactionCellCounterpartyConfig?,
         invitationStatus: InvitationStatus?,
         transactionStatus: TransactionStatus,
         memo: String?,
         amountFactory: MockAmountsFactory? = nil,
         receiverAddress: String? = nil,
         addressProvidedToSender: String? = nil,
         isLightningTransfer: Bool = false,
         lightningInvoice: String? = nil) {

      let sats = 50_000
      let amtFactory = amountFactory ?? MockDropBitVM.amountFactory(for: sats,
                                                                    invitationStatus: invitationStatus,
                                                                    transactionStatus: transactionStatus)

      super.init(walletTxType: walletTxType,
                 direction: direction,
                 status: transactionStatus,
                 onChainConfirmations: nil,
                 isLightningTransfer: isLightningTransfer,
                 receiverAddress: receiverAddress,
                 addressProvidedToSender: addressProvidedToSender,
                 lightningInvoice: lightningInvoice,
                 selectedCurrency: .fiat,
                 amountFactory: amtFactory,
                 counterpartyConfig: counterparty,
                 invitationStatus: invitationStatus,
                 memo: memo,
                 memoIsShared: true,
                 date: Date())
    }

    convenience init(walletTxType: WalletTransactionType,
                     direction: TransactionDirection,
                     identity: UserIdentityType,
                     invitationStatus: InvitationStatus?,
                     transactionStatus: TransactionStatus,
                     addressProvidedToSender: String? = nil) {

      var maybeMemo: String? = "Coffee ☕️"
      if let inviteStatus = invitationStatus, inviteStatus != .completed, direction == .in {
        maybeMemo = nil
      }

      var maybeReceiverAddress: String?
      if (transactionStatus == .completed) && walletTxType == .onChain {
        maybeReceiverAddress = MockDropBitVM.mockValidBitcoinAddress()
      }

      self.init(walletTxType: walletTxType, direction: direction, counterparty: identity.testCounterparty,
                invitationStatus: invitationStatus, transactionStatus: transactionStatus, memo: maybeMemo,
                receiverAddress: maybeReceiverAddress, addressProvidedToSender: addressProvidedToSender)
    }

    static func amountFactory(for sats: Int, invitationStatus: InvitationStatus?, transactionStatus: TransactionStatus) -> MockAmountsFactory {
//      let cents = 350
//      let fiatWhenInvited = NSDecimalNumber(integerAmount: cents, currency: .USD)
//      let fiatWhenTransacted = NSDecimalNumber(integerAmount: cents + 5, currency: .USD)

      var amtFactory = MockDetailCellVM.testAmountFactory(sats: sats)
      if let inviteStatus = invitationStatus {
        switch inviteStatus {
        case .notSent:
          break
        case .requestSent, .addressSent, .canceled, .expired:
          amtFactory = MockDetailCellVM.testAmountFactory(sats: sats)
        case .completed:
          amtFactory = MockDetailCellVM.testAmountFactory(sats: sats)
        }
      } else if transactionStatus == .completed {
        amtFactory = MockDetailCellVM.testAmountFactory(sats: sats)
      }

      return amtFactory
    }
  }

  func generatePhoneAndTwitterDropBitItems(categories: [MockDataDropBitCategory]) -> [MockTransactionDetailValidCellViewModel] {
    let identities: [UserIdentityType] = [.phone, .twitter]
    return identities.flatMap { identity -> [MockTransactionDetailValidCellViewModel] in
      return categories.flatMap { category -> [MockTransactionDetailValidCellViewModel] in
        switch category {
        case .valid:  return self.generateValidItems(identity)
        case .invalid:  return self.generateInvalidItems(identity)
        }
      }
    }
  }

  func lightningTransfer(walletTxType: WalletTransactionType, direction: TransactionDirection) -> MockTransactionDetailValidCellViewModel {
    let amountFactory = MockDetailCellVM.testAmountFactory(sats: 1_000_000)
    return MockTransactionDetailValidCellViewModel(walletTxType: walletTxType, direction: direction, status: .completed, onChainConfirmations: 1,
                                              isLightningTransfer: true, receiverAddress: MockDetailCellVM.mockValidBitcoinAddress(),
                                              addressProvidedToSender: nil, lightningInvoice: nil, selectedCurrency: .fiat,
                                              amountFactory: amountFactory, counterpartyConfig: nil, invitationStatus: nil,
                                              memo: nil, memoIsShared: false, date: Date())
  }

  func genericOnChainTransactionWithPrivateMemo(direction: TransactionDirection) -> MockTransactionDetailValidCellViewModel {
    let memo: String? = (direction == .out) ? "Car" : nil
    let memoIsShared = false

    let amountFactory = MockDetailCellVM.testAmountFactory(sats: 88_235_000)
    return MockTransactionDetailValidCellViewModel(walletTxType: .onChain, direction: direction, status: .completed, onChainConfirmations: 1,
                                              isLightningTransfer: false, receiverAddress: MockDetailCellVM.mockValidBitcoinAddress(),
                                              addressProvidedToSender: nil, lightningInvoice: nil, selectedCurrency: .fiat,
                                              amountFactory: amountFactory, counterpartyConfig: nil, invitationStatus: nil,
                                              memo: memo, memoIsShared: memoIsShared, date: Date())
  }

  func lightningInvoice(hours: Int?) -> MockTransactionDetailInvoiceCellViewModel {
    return MockTransactionDetailInvoiceCellViewModel(hoursUntilExpiration: hours)
  }

  private func generateValidItems(_ identity: UserIdentityType) -> [MockTransactionDetailValidCellViewModel] {
    return [
      self.invitePendingSender(identity),
      self.invitePendingReceiver(identity),
      self.transferCompleteSender(identity),
      self.transferCompleteReceiver(identity),
      self.inviteCompleteSender(identity),
      self.inviteCompleteReceiver(identity)
    ]
  }

  private func generateInvalidItems(_ identity: UserIdentityType) -> [MockTransactionDetailInvalidCellViewModel] {
    return [
      self.inviteExpiredSender(identity),
      self.inviteExpiredReceiver(identity),
      self.inviteCanceledSender(identity),
      self.inviteCanceledReceiver(identity)
    ]
  }

  private func invitePendingSender(_ identity: UserIdentityType) -> MockTransactionDetailValidCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .out, identity: identity, invitationStatus: .requestSent, transactionStatus: .pending)
  }

  private func invitePendingReceiver(_ identity: UserIdentityType) -> MockTransactionDetailValidCellViewModel {
    var providedAddress: String?
    if walletTxType == .onChain {
      providedAddress = MockDropBitVM.mockValidBitcoinAddress()
    }

    return MockDropBitVM(walletTxType: walletTxType, direction: .in, identity: identity, invitationStatus: .addressSent,
                         transactionStatus: .pending, addressProvidedToSender: providedAddress)
  }

  private func transferCompleteSender(_ identity: UserIdentityType) -> MockTransactionDetailValidCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .out, identity: identity,
                         invitationStatus: nil, transactionStatus: .completed)
  }

  private func transferCompleteReceiver(_ identity: UserIdentityType) -> MockTransactionDetailValidCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .in, identity: identity,
                         invitationStatus: nil, transactionStatus: .completed)
  }

  private func inviteCompleteSender(_ identity: UserIdentityType) -> MockTransactionDetailValidCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .out, identity: identity,
                         invitationStatus: .completed, transactionStatus: .completed)
  }

  private func inviteCompleteReceiver(_ identity: UserIdentityType) -> MockTransactionDetailValidCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .in, identity: identity,
                         invitationStatus: .completed, transactionStatus: .completed)
  }

  private func inviteExpiredSender(_ identity: UserIdentityType) -> MockTransactionDetailInvalidCellViewModel {
    return MockDetailInvalidCellVM(dropBitWith: walletTxType, direction: .out, identity: identity,
                                   invitationStatus: .expired, transactionStatus: .expired)
  }

  private func inviteExpiredReceiver(_ identity: UserIdentityType) -> MockTransactionDetailInvalidCellViewModel {
    return MockDetailInvalidCellVM(dropBitWith: walletTxType, direction: .in, identity: identity,
                                   invitationStatus: .expired, transactionStatus: .expired)
  }

  private func inviteCanceledSender(_ identity: UserIdentityType) -> MockTransactionDetailInvalidCellViewModel {
    return MockDetailInvalidCellVM(dropBitWith: walletTxType, direction: .out, identity: identity,
                                   invitationStatus: .canceled, transactionStatus: .canceled)
  }

  private func inviteCanceledReceiver(_ identity: UserIdentityType) -> MockTransactionDetailInvalidCellViewModel {
    return MockDetailInvalidCellVM(dropBitWith: walletTxType, direction: .in, identity: identity,
                                   invitationStatus: .canceled, transactionStatus: .canceled)
  }

}

extension UserIdentityType {
  var testCounterparty: TransactionCellCounterpartyConfig {
    switch self {
    case .phone:
      return TransactionCellCounterpartyConfig(displayPhoneNumber: "(330) 456-7890")
    case .twitter:
      let twitterConfig = MockDetailCellVM.mockTwitterConfig()
      return TransactionCellCounterpartyConfig(twitterConfig: twitterConfig)
    }
  }
}
