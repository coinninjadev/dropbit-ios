//
//  TransactionDetailCellViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 10/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class TransactionDetailCellViewModel: TransactionSummaryCellViewModel, TransactionDetailCellViewModelType {

  var memoIsShared: Bool
  var date: Date
  var onChainConfirmations: Int?
  var addressProvidedToSender: String?
  var paymentIdIsValid: Bool
  var invitationStatus: InvitationStatus?

  init(object: TransactionDetailCellViewModelObject,
       inputs: TransactionViewModelInputs) {
    self.memoIsShared = object.memoIsShared
    self.date = object.primaryDate
    self.onChainConfirmations = object.onChainConfirmations
    self.addressProvidedToSender = object.addressProvidedToSender
    self.paymentIdIsValid = object.paymentIdIsValid
    self.invitationStatus = object.invitationStatus

    super.init(object: object, inputs: inputs)
  }

}

protocol TransactionDetailCellViewModelObject: TransactionSummaryCellViewModelObject {

  var memoIsShared: Bool { get }
  var primaryDate: Date { get }
  var onChainConfirmations: Int? { get }
  var addressProvidedToSender: String? { get }
  var paymentIdIsValid: Bool { get }
  var invitationStatus: InvitationStatus? { get }

}
