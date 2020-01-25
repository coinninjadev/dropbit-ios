//
//  DropBitUrlFactory.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 1/23/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class DropBitUrlFactory {

  enum DropBitURL: String {
    case widget

    static var scheme: String {
      return "dropbit"
    }

    var queryItems: [URLQueryItem] {
      switch self {
      case .widget:
        return [URLQueryItem(name: DropBitURL.widget.rawValue, value: "true")]
      }
    }
  }

  static func buildUrl(for url: DropBitURL) -> URL? {
    var components = URLComponents()
    components.scheme = DropBitURL.scheme
    components.queryItems = url.queryItems

    do {
      return try components.asURL()
    } catch {
      return nil
    }
  }
}
