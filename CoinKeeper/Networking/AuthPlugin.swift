//
//  AuthPlugin.swift
//  DropBit
//
//  Created by Ben Winters on 5/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Moya
import Result

class TokenSource {
  var token: String?
  init() { }
}

extension TargetType {

  var endpointDescription: String {
    return "\(self.baseURL)/\(self.path) \(self.method.rawValue)"
  }

}

struct AuthPlugin: PluginType {

  /// Handles signing the request body and composing the other DefaultHeaders
  weak var headerDelegate: HeaderDelegate?

  func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {

    var request = request

    let shouldSignBody = !target.path.starts(with: CoinNinjaProvider.thunderdomeBasePath)
    guard let headers = headerDelegate?.createHeaders(
      for: request.httpBody,
      signBodyIfAvailable: shouldSignBody) else {
        return request
    }

    request.addValue(headers.appVersion, forCNHeaderField: .appVersion)
    request.addValue(headers.devicePlatform, forCNHeaderField: .devicePlatform)
    request.addValue(headers.timeStamp, forCNHeaderField: .authTimestamp)
    request.addValue(headers.buildEnvironment, forCNHeaderField: .buildEnvironment)
    request.addValue(headers.udid, forCNHeaderField: .udid)

    if let pubKeyString = headers.pubKeyString {
      request.addValue(pubKeyString, forCNHeaderField: .pubKeyString)
    }

    if let deviceId = headers.deviceId?.uuidString.lowercased() {
      request.addValue(deviceId, forCNHeaderField: .deviceId)
    }

    headers.signature.flatMap { request.addValue($0, forCNHeaderField: .authSignature) }

    // Only set these header values if they are nil. In some cases, like registering the user,
    // the headers are only in memory until a later state. So the target will provide these header values,
    // which should not be overwritten with what the headerDelegate provides.
    if request.value(forCNHeaderParameter: .authWalletId) == nil {
      headers.walletId.flatMap { request.addValue($0, forCNHeaderField: .authWalletId) }
    }

    if request.value(forCNHeaderParameter: .authUserId) == nil {
      headers.userId.flatMap { request.addValue($0, forCNHeaderField: .authUserId) }
    }

    return request
  }

  func willSend(_ request: RequestType, target: TargetType) {
    guard let innerRequest = request.request else { return }
    log.debugPrivate(target.endpointDescription)
    log.verboseNetwork("\(innerRequest.allHTTPHeaderFields ?? [:])")
    if let bodyData = innerRequest.httpBody {
      let bodyString = String(data: bodyData, encoding: .utf8) ?? "-"
      log.info("Body: %@", privateArgs: [bodyString])
    }
  }

  func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
    switch result {
    case .success(let response):
      let summary = "\(target.endpointDescription) \(response.statusCode)"
      log.debug(summary)
      #if DEBUG
      let responseDesc = "Response: \n" + response.data.prettyPrinted()
      log.verboseNetwork(responseDesc)
      #endif
    case .failure(let error):
      let errorDesc = error.errorDescription ?? "unknown Moya error"
      let errorMessage = error.errorMessage ?? "-" //error message from server
      log.error("\(target.endpointDescription) \(errorDesc), \(errorMessage)")
    }
  }

}
