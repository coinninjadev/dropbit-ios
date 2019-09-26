//
//  MockTransactionDataGenerator.swift
//  DropBitTests
//
//  Created by Ben Winters on 8/27/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum MockDataDropBitCategory {
  case valid, invalid
}

struct MockDetailDataGenerator {

  let walletTxType: WalletTransactionType

  class MockDropBitVM: MockTransactionDetailCellViewModel {

    init(walletTxType: WalletTransactionType,
         direction: TransactionDirection,
         counterparty: TransactionCellCounterpartyConfig?,
         invitationStatus: InvitationStatus?,
         transactionStatus: TransactionStatus,
         amountDetails: TransactionAmountDetails? = nil,
         isLightningTransfer: Bool = false,
         lightningInvoice: String? = nil) {

      let memo = "Coffee ☕️"
      let sats = 50_000
      let amtDetails = amountDetails ?? MockDropBitVM.amountDetails(for: sats,
                                                                    invitationStatus: invitationStatus,
                                                                    transactionStatus: transactionStatus)

      super.init(walletTxType: walletTxType,
                 direction: direction,
                 status: transactionStatus,
                 onChainConfirmations: nil,
                 isLightningTransfer: isLightningTransfer,
                 receiverAddress: nil,
                 addressProvidedToSender: nil,
                 lightningInvoice: lightningInvoice,
                 paymentIdIsValid: true,
                 selectedCurrency: .fiat,
                 amountDetails: amtDetails,
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
                     transactionStatus: TransactionStatus) {
      self.init(walletTxType: walletTxType, direction: direction, counterparty: identity.testCounterparty,
                invitationStatus: invitationStatus, transactionStatus: transactionStatus)
    }

    static func amountDetails(for sats: Int, invitationStatus: InvitationStatus?, transactionStatus: TransactionStatus) -> TransactionAmountDetails {
      let cents = 350
      let fiatWhenInvited = NSDecimalNumber(integerAmount: cents, currency: .USD)
      let fiatWhenTransacted = NSDecimalNumber(integerAmount: cents + 5, currency: .USD)

      var amtDetails = MockDetailCellVM.testAmountDetails(sats: sats)
      if let inviteStatus = invitationStatus {
        switch inviteStatus {
        case .notSent:
          break
        case .requestSent, .addressSent, .canceled, .expired:
          amtDetails = MockDetailCellVM.testAmountDetails(sats: sats, fiatWhenInvited: fiatWhenInvited, fiatWhenTransacted: nil)
        case .completed:
          amtDetails = MockDetailCellVM.testAmountDetails(sats: sats, fiatWhenInvited: fiatWhenInvited, fiatWhenTransacted: fiatWhenTransacted)
        }
      }

      return amtDetails
    }
  }

  func generatePhoneAndTwitterDropBitItems(categories: [MockDataDropBitCategory]) -> [MockTransactionDetailCellViewModel] {
    let identities: [UserIdentityType] = [.phone, .twitter]
    return identities.flatMap { identity -> [MockTransactionDetailCellViewModel] in
      return categories.flatMap { category -> [MockTransactionDetailCellViewModel] in
        switch category {
        case .valid:  return self.generateValidItems(identity)
        case .invalid:  return self.generateInvalidItems(identity)
        }
      }
    }
  }

  private func generateValidItems(_ identity: UserIdentityType) -> [MockTransactionDetailCellViewModel] {
    return [
      self.invitePendingSender(identity),
      self.invitePendingReceiver(identity),
      self.transferCompleteSender(identity),
      self.transferCompleteReceiver(identity),
      self.inviteCompleteSender(identity),
      self.inviteCompleteReceiver(identity)
    ]
  }

  private func generateInvalidItems(_ identity: UserIdentityType) -> [MockTransactionDetailCellViewModel] {
    return [
      self.inviteExpiredSender(identity),
      self.inviteExpiredReceiver(identity),
      self.inviteCanceledSender(identity),
      self.inviteCanceledReceiver(identity)
    ]
  }

  private func invitePendingSender(_ identity: UserIdentityType) -> MockTransactionDetailCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .out, identity: identity, invitationStatus: .requestSent, transactionStatus: .pending)
  }

  private func invitePendingReceiver(_ identity: UserIdentityType) -> MockTransactionDetailCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .in, identity: identity, invitationStatus: .addressSent, transactionStatus: .pending)
  }

  private func transferCompleteSender(_ identity: UserIdentityType) -> MockTransactionDetailCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .out, identity: identity, invitationStatus: nil, transactionStatus: .completed)
  }

  private func transferCompleteReceiver(_ identity: UserIdentityType) -> MockTransactionDetailCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .in, identity: identity, invitationStatus: nil, transactionStatus: .completed)
  }

  private func inviteCompleteSender(_ identity: UserIdentityType) -> MockTransactionDetailCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .out, identity: identity, invitationStatus: .completed, transactionStatus: .completed)
  }

  private func inviteCompleteReceiver(_ identity: UserIdentityType) -> MockTransactionDetailCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .in, identity: identity, invitationStatus: .completed, transactionStatus: .completed)
  }

  private func inviteExpiredSender(_ identity: UserIdentityType) -> MockTransactionDetailCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .out, identity: identity, invitationStatus: .expired, transactionStatus: .expired)
  }

  private func inviteExpiredReceiver(_ identity: UserIdentityType) -> MockTransactionDetailCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .in, identity: identity, invitationStatus: .expired, transactionStatus: .expired)
  }

  private func inviteCanceledSender(_ identity: UserIdentityType) -> MockTransactionDetailCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .out, identity: identity, invitationStatus: .canceled, transactionStatus: .canceled)
  }

  private func inviteCanceledReceiver(_ identity: UserIdentityType) -> MockTransactionDetailCellViewModel {
    return MockDropBitVM(walletTxType: walletTxType, direction: .in, identity: identity, invitationStatus: .canceled, transactionStatus: .canceled)
  }

}

extension UserIdentityType {
  var testCounterparty: TransactionCellCounterpartyConfig {
    switch self {
    case .phone:
      return TransactionCellCounterpartyConfig(displayPhoneNumber: "(123) 456-7890")
    case .twitter:
      let twitterConfig = MockDetailCellVM.mockTwitterConfig()
      return TransactionCellCounterpartyConfig(twitterConfig: twitterConfig)
    }
  }
}
