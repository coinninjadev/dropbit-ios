//
//  CoinNinjaProvider.swift
//  DropBit
//
//  Created by Ben Winters on 9/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Moya
import PromiseKit
import os.log

/// Closure type for signing CoinNinja API requests and adding other standard headers
/// Data should be the request body
protocol HeaderDelegate: AnyObject {
  func createHeaders(for bodyData: Data?) -> DefaultHeaders?
}

/// A protocol to hold logic shared by its descendant providers.
protocol CoinNinjaProviderType: AnyObject {
  var headerDelegate: HeaderDelegate? { get set }
  var provider: MoyaProvider<MultiTarget> { get }
}

class CoinNinjaProvider: CoinNinjaProviderType {
  weak var headerDelegate: HeaderDelegate?
}

extension CoinNinjaProviderType {

  var logger: OSLog {
    return OSLog(subsystem: "com.coinninja.coinkeeper.coinninjaprovider", category: "provider")
  }

  var provider: MoyaProvider<MultiTarget> {
    var plugins: [PluginType] = []
    if let delegate = headerDelegate {
      plugins.append(AuthPlugin(headerDelegate: delegate))
    }

    return MoyaProvider<MultiTarget>(
      manager: CKAlamofireSessionManager.shared,
      plugins: plugins
    )
  }

  func request<T: CoinNinjaTargetType>(_ target: T) -> Promise<T.ResponseType> {
    return Promise { seal in
      provider.request(MultiTarget(target)) { result in
        switch result {
        case .success(let response):
          do {
            let object = try response.map(T.ResponseType.self, using: T.ResponseType.decoder)
            let validatedObject = try T.ResponseType.validateResponse(object)
            seal.fulfill(validatedObject)
          } catch {
            seal.reject(error)
          }

        case .failure(let error):
          os_log("Failure from %@ request: %{private}@", log: self.logger, type: .error, target.path, error.responseDescription)
          if let networkError = target.networkError(for: error) {
            seal.reject(networkError)
          } else {
            seal.reject(error)
          }
        }
      }
    }
  }

  func requestList<T: CoinNinjaTargetType>(_ target: T) -> Promise<[T.ResponseType]> {
    return Promise { seal in
      provider.request(MultiTarget(target)) { result in
        switch result {
        case .success(let response):
          do {
            let objects = try response.map([T.ResponseType].self, using: T.ResponseType.decoder)
            let validatedObjects = try objects.map { try T.ResponseType.validateResponse($0) }
            seal.fulfill(validatedObjects)
          } catch {
            seal.reject(error)
          }

        case .failure(let error):
          os_log("Failure from %@ request: %{private}@", log: self.logger, type: .error, target.path, error.responseDescription)
          if let networkError = target.networkError(for: error) {
            seal.reject(networkError)
          } else {
            seal.reject(error)
          }
        }
      }
    }
  }

  func requestVoid<T: CoinNinjaTargetType>(_ target: T) -> Promise<Void> {
    return Promise { seal in
      provider.request(MultiTarget(target)) { result in
        switch result {
        case .success:
          seal.fulfill(())

        case .failure(let error):
          os_log("Failure from %@ request: %{private}@", log: self.logger, type: .error, target.path, error.responseDescription)
          if let networkError = target.networkError(for: error) {
            seal.reject(networkError)
          } else {
            seal.reject(error)
          }
        }
      }
    }
  }

  func requestObject<T: CoinNinjaTargetType>(_ target: T) -> Promise<JSONObject> {
    return Promise { seal in
      provider.request(MultiTarget(target)) { result in
        switch result {
        case .success(let response):
          do {
            if let jsonObject = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? JSONObject {
              seal.fulfill(jsonObject)
            } else {
              seal.reject(CKNetworkError.badResponse)
            }
          } catch {
            seal.reject(error)
          }

        case .failure(let error):
          os_log("Failure from %@ request: %{private}@", log: self.logger, type: .error, target.path, error.responseDescription)
          if let networkError = target.networkError(for: error) {
            seal.reject(networkError)
          } else {
            seal.reject(error)
          }
        }
      }
    }
  }

}
