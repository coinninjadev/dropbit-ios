//
//  TransactionHistoryDetailCellAddressViewConfigurable.swift
//  DropBit
//
//  Created by Ben Winters on 9/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

typealias AddressViewConfigurable = TransactionHistoryDetailCellAddressViewConfigurable
protocol TransactionHistoryDetailCellAddressViewConfigurable {
  var walletTxType: WalletTransactionType { get }
  var receiverAddress: String? { get }
  var addressProvidedToSender: String? { get }
  var broadcastFailed: Bool { get }
  var invitationStatus: InvitationStatus? { get }
}

struct ShouldHideAddressViews {
  let containerView: Bool
  let statusLabel: Bool
}

struct AddressViewConfig: AddressViewConfigurable {
  var walletTxType: WalletTransactionType
  var receiverAddress: String?
  var addressProvidedToSender: String?
  var broadcastFailed: Bool
  var invitationStatus: InvitationStatus?
}

extension TransactionHistoryDetailCellAddressViewConfigurable {

  var shouldHideAddressViews: ShouldHideAddressViews {
    if let invitationStatus = invitationStatus {
      switch invitationStatus {
      case .completed, .addressProvided:
        return ShouldHideAddressViews(containerView: false, statusLabel: true)
      case .canceled, .expired:
        return ShouldHideAddressViews(containerView: true, statusLabel: true)
      default:
        return ShouldHideAddressViews(containerView: true, statusLabel: false)
      }
    } else {
      let shouldHideAddressButton = !addressButtonIsActive
      return ShouldHideAddressViews(containerView: shouldHideAddressButton, statusLabel: !shouldHideAddressButton)
    }
  }

  var addressButtonIsActive: Bool {
    guard !broadcastFailed else { return false }
    if addressStatusLabelString == nil, let address = relevantAddress, address.isValidBitcoinAddress() {
      return true
    } else {
      return false
    }
  }

  /// The address string to display and look up on block explorer if tapped
  var relevantAddress: String? {
    return receiverAddress ?? addressProvidedToSender
  }

  var shouldEnableAddressTextButton: Bool {
    return addressButtonIsActive
  }

  var shouldHideAddressImageButton: Bool {
    return !addressButtonIsActive
  }

  /// Label not visible if address exists
  var addressStatusLabelString: String? {
    guard let status = invitationStatus else { return nil }
    switch status {
    case .requestSent:
    switch walletTxType {
    case .onChain:      return "Waiting on Bitcoin address"
    case .lightning:    return "Waiting on Lightning invoice"
    }

    case .addressProvided:  return addressProvidedToSender ?? "Waiting for sender approval"
    default:            return nil
    }
  }

}
