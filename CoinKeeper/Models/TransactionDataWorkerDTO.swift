//
//  TransactionDataWorkerDTO.swift
//  DropBit
//
//  Created by BJ Miller on 7/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

struct TransactionDataWorkerDTO {
  var checkinResponse: CheckInResponse?
  var atsResponses: [AddressTransactionSummaryResponse] = []
  var txResponses: [TransactionResponse] = []
  var txNotificationResponses: [TransactionNotificationResponse] = []

  init(
    checkinResponse: CheckInResponse? = nil,
    atsResponses: [AddressTransactionSummaryResponse] = [],
    txResponses: [TransactionResponse] = [],
    txNotificationResponses: [TransactionNotificationResponse] = []
    ) {
    self.checkinResponse = checkinResponse
    self.atsResponses = atsResponses
    self.txResponses = txResponses
    self.txNotificationResponses = txNotificationResponses
  }

  func merged(with dto: TransactionDataWorkerDTO) -> TransactionDataWorkerDTO {
    var copy = self
    dto.checkinResponse.map { copy.checkinResponse = $0 }
    copy.atsResponses = (copy.atsResponses + dto.atsResponses).uniqued()
    copy.txResponses = (copy.txResponses + dto.txResponses).uniqued()
    copy.txNotificationResponses = (copy.txNotificationResponses + dto.txNotificationResponses).uniqued()
    return copy
  }

  var atsResponsesTxIds: [String] {
    return atsResponses.map { $0.txid }
  }

  var uniqueAddresses: [String] {
    return atsResponses.map { $0.address }.uniqued()
  }

  var blockHeight: Int {
    return checkinResponse?.blockheight ?? 0
  }
}

extension TransactionDataWorkerDTO: CustomDebugStringConvertible {
  var debugDescription: String {
    return "response blockheight: \(blockHeight), txResponses: \(txResponses.count), atsResponses: \(atsResponses.count)"
  }
}
