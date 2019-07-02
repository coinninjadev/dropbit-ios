//
//  NetworkManager+AddressRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

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

    log.debug("fetching responses for addresses: page %d, addresses %@.", privateArgs: [page, addresses])
    return cnProvider.requestList(AddressesTarget.query(addresses, page, perPage, afterDate))
      .get { responses in
        if !isIncremental, responses.isEmpty, page == 1 {
          log.debug("response is empty during full sync, rejecting with .emptyResponse")
          throw CKNetworkError.emptyResponse
        }
      }
      .then { (responses: [AddressTransactionSummaryResponse]) -> Promise<[AddressTransactionSummaryResponse]> in
        if responses.count == perPage {
          let nextPage = page + 1
          let combined = aggregateResponses + responses
          log.debug("combined response count: \(combined.count)")
          return self.atsResponses(for: addresses, afterDate: afterDate, page: nextPage, perPage: perPage, with: combined)

        } else {
          log.debug("responses count (\(responses.count)) less than perPage limit, returning aggregated responses")
          return Promise.value(aggregateResponses + responses)
        }
    }
  }

}
