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
  func fetchTransactionSummaries(for address: String) -> Promise<[AddressTransactionSummaryResponse]>
}

extension NetworkManager: AddressRequestable {

  func fetchTransactionSummaries(for addresses: [String], afterDate: Date?) -> Promise<[AddressTransactionSummaryResponse]> {
    return atsResponses(for: addresses, afterDate: afterDate)
  }

  func fetchTransactionSummaries(for address: String) -> Promise<[AddressTransactionSummaryResponse]> {
    return cnProvider.requestList(AddressesTarget.address(address))
  }

  private func atsResponses(
    for addresses: [String],
    afterDate: Date?,
    page: Int = 1,
    perPage: Int = 25,
    with aggregateResponses: [AddressTransactionSummaryResponse] = []
    ) -> Promise<[AddressTransactionSummaryResponse]> {

    let isIncremental = afterDate != nil

    os_log("fetching responses for addresses: page %d, addresses: %@.", log: self.logger, type: .debug, page, addresses)
    return cnProvider.requestList(AddressesTarget.query(addresses, page, perPage, afterDate))
      .get { responses in
        if !isIncremental, responses.isEmpty, page == 1 {
          os_log("response is empty during full sync, rejecting with .emptyResponse", log: self.logger, type: .debug)
          throw CKNetworkError.emptyResponse
        }
      }
      .then { (responses: [AddressTransactionSummaryResponse]) -> Promise<[AddressTransactionSummaryResponse]> in
        // NOTE: Currently the server passes the `perPage` parameter to elastic search which uses it to limit `Transaction` objects.
        // The server then maps those results into `AddressTransaction` objects (i.e. `AddressTransactionSummaryResponse`), each of which
        // represent the details of a single address for the transaction. So there are typically more of these objects than the original
        // Transaction objects which means that the `perPage` variable defined here will not be strictly observed by the response,
        // e.g. a query where perPage=25 could return 37 AddressTransactionSummaryResponse objects that represent 25 transactions.
        if responses.count >= perPage {
          let nextPage = page + 1
          let combined = aggregateResponses + responses
          os_log("combined response count: %d", log: self.logger, type: .debug, combined.count)
          return self.atsResponses(for: addresses, afterDate: afterDate, page: nextPage, perPage: perPage, with: combined)

        } else {
          os_log("responses count (%d) less than perPage limit, returning aggregated responses", log: self.logger, type: .debug, responses.count)
          return Promise.value(aggregateResponses + responses)
        }
    }
  }

}
