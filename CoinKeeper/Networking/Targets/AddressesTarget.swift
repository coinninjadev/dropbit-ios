//
//  AddressesTarget.swift
//  DropBit
//
//  Created by Ben Winters on 9/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya
import Foundation

public enum AddressesTarget: CoinNinjaTargetType {
  typealias ResponseType = AddressTransactionSummaryResponse

  /// multiAddress params - addresses: [String], pageNumber: Int, perPage: Int
  case query([String], Int, Int, Date?)
  case address(String)

}

extension AddressesTarget {

  var basePath: String {
    return "addresses"
  }

  var subPath: String? {
    switch self {
    case .query:                return "query"
    case .address(let address): return address
    }
  }

  public var method: Moya.Method {
    switch self {
    case .query:    return .post
    case .address:  return .get
    }
  }

  public var task: Task {
    switch self {
    case .query(let addresses, let page, let perPage, let minDate):
      guard let data = queryBody(addresses: addresses, minDate: minDate) else { return .requestPlain }
      return .requestCompositeData(bodyData: data, urlParameters: ["page": page, "perPage": perPage])
    case .address:
      return .requestPlain
    }
  }

  public var validationType: ValidationType {
    return .customCodes([200, 404])
  }

  private func queryBody(addresses: [String], minDate: Date?) -> Data? {
    let body = AddressQueryBody(addresses: addresses, minDate: minDate)
    let data = try? customEncoder.encode(body)
    return data
  }

}

struct AddressQueryBody: Encodable {
  var query: AddressQueryQuery

  init(addresses: [String], minDate: Date?) {
    let timeAfter = minDate.map { Int($0.timeIntervalSince1970) }
    let terms = AddressQueryTerms(address: addresses, timeAfter: timeAfter)
    self.query = AddressQueryQuery(terms: terms)
  }
}

struct AddressQueryQuery: Encodable {
  let terms: AddressQueryTerms
}

struct AddressQueryTerms: Encodable {
  let address: [String]
  let timeAfter: Int?
}
