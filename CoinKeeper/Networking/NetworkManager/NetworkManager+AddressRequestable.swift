//
//  NetworkManager+AddressRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import os.log
import PromiseKit

protocol AddressRequestable: AnyObject {
  func fetchTransactionSummaries(for addresses: [String], afterDate: Date?) -> Promise<[AddressTransactionSummaryResponse]>
}

extension NetworkManager: AddressRequestable {

  func fetchTransactionSummaries(for addresses: [String], afterDate: Date?) -> Promise<[AddressTransactionSummaryResponse]> {
    return atsResponses(for: addresses, afterDate: afterDate)
  }

  private func atsResponses(
    for addresses: [String],
    afterDate: Date?,
    page: Int = 1,
    perPage: Int = 25,
    with accumulatedResponses: [AddressTransactionSummaryResponse] = []
    ) -> Promise<[AddressTransactionSummaryResponse]> {

    os_log("fetching responses for addresses: page %d, addresses: %@.", log: self.logger, type: .debug, page, addresses)
    return cnProvider.requestList(AddressesTarget.query(addresses, page, perPage, afterDate))
      .get { responses in
        if responses.isEmpty && page == 1 {
          os_log("response is empty, rejecting with .emptyResponse", log: self.logger, type: .debug)
          throw CKNetworkError.emptyResponse
        }
      }
      .then { (responses: [AddressTransactionSummaryResponse]) -> Promise<[AddressTransactionSummaryResponse]> in
        guard responses.count == perPage else {
          os_log("responses count (%d) less than perPage limit, returning promise", log: self.logger, type: .debug, responses.count)
          return Promise.value(accumulatedResponses + responses)
        }

        let nextPage = page + 1
        let combined = accumulatedResponses + responses
        os_log("combined response count: %d", log: self.logger, type: .debug, combined.count)
        return self.atsResponses(for: addresses, afterDate: afterDate, page: nextPage, perPage: perPage, with: combined)
    }
  }

}
