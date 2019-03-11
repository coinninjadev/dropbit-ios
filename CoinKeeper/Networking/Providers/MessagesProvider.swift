//
//  MessagesProvider.swift
//  CoinKeeper
//
//  Created by Mitch on 9/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import Moya
import PromiseKit
import os.log

class Messages {
  enum Level: String, Codable {
    case fatal
    case error
    case warn
    case success
    case info
    case debug
    case trace

    var displayPriority: Int {
      switch self {
      case .error:
        return 7
      case .warn:
        return 6
      case .success:
        return 5
      case .info, .debug, .trace, .fatal:
        return 0
      }
    }
  }

  enum Platform: String, Codable {
    case ios
    case android
    case all
    case web
  }
}

protocol MessagesProviderType: ProviderType {
  func query() -> Promise<[MessageResponse]>
}

class MessagesProvider: MessagesProviderType {

  weak var headerDelegate: HeaderDelegate?
  private let logger = OSLog(subsystem: "com.coinninja.coinkeeper.messsagesprovider", category: "messages")

  private func buildElasticRequest() -> ElasticRequest {
    let terms = ElasticTerms(platforms: [.all, .ios]), script = ElasticScript(id: "semver", version: Global.version.value),
    query = ElasticQuery(range: nil, script: script, term: nil, terms: terms)

    return ElasticRequest(query: query)
  }

  func query() -> Promise<[MessageResponse]> {
    return Promise { seal in
      provider.request(.messages(buildElasticRequest())) { (result) in
        switch result {
        case .success(let response):
          do {
            let decodedResponse = try self.customDecoder.decode([MessageResponse].self, from: response.data)
            seal.fulfill(decodedResponse)
          } catch {
            os_log("Failed to decode response: %@", log: self.logger, type: .debug, error.localizedDescription)
            seal.reject(ReachabilityError.reachabilityFailed)
          }
        case .failure(let error):
          let errorDesc = error.errorDescription ?? "unknown Moya error"
          let errorMessage = error.errorMessage ?? "-" //error message from server
          os_log("Messages error: %{private}@\n\t%{private}@", log: self.logger, type: .error, errorDesc, errorMessage)
          switch error.response?.statusCode {
          case 401?: seal.reject(error)
          default: seal.reject(ReachabilityError.reachabilityFailed)
          }
        }
      }
    }
  }
}
