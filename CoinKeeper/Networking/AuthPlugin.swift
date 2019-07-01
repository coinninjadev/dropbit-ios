//
//  AuthPlugin.swift
//  CoinKeeper
//
//  Created by Ben Winters on 5/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit
import Moya
import Result
import os.log

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
  let logger = OSLog(subsystem: "com.coinninja.coinkeeper.authplugin", category: "auth_plugin")

  func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {

    var request = request

    guard let headers: DefaultHeaders = headerDelegate?.createHeaders(for: request.httpBody) else {
      return request
    }

    request.addValue(headers.appVersion, forCNHeaderField: .appVersion)
    request.addValue(headers.devicePlatform, forCNHeaderField: .devicePlatform)
    request.addValue(headers.timeStamp, forCNHeaderField: .authTimestamp)
    request.addValue(headers.buildEnvironment, forCNHeaderField: .buildEnvironment)

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

    os_log("[will_send] %{private}@", log: self.logger, type: .debug, target.endpointDescription)
    os_log("%{private}@", log: self.logger, type: .debug, innerRequest.allHTTPHeaderFields ?? [:])
    if let bodyData = innerRequest.httpBody {
      let bodyString = String(data: bodyData, encoding: .utf8) ?? "-"
      os_log("Body: %{private}@", log: self.logger, type: .debug, bodyString)
    }
  }

  func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {

    switch result {
    case .success(let response):
      let fullDesc = "[did_receive] \(target.endpointDescription) \(response.statusCode)"
      os_log("%@", log: self.logger, type: .debug, fullDesc)
    case .failure(let error):
      let errorDesc = error.errorDescription ?? "unknown Moya error"
      let errorMessage = error.errorMessage ?? "-" //error message from server

      os_log("%@ error: %@, %@", log: self.logger, type: .debug, target.endpointDescription, errorDesc, errorMessage)
    }
  }

  private func prettyPrint(_ response: Response) {
    prettyPrint(data: response.data)
  }

  private func prettyPrint(_ request: RequestType) {
    guard let data = request.request?.httpBody else {
      print("No available httpBody in request")
      return
    }
    prettyPrint(data: data)
  }

  private func prettyPrint(data: Data) {
    let resString = data.prettyPrinted()
    print("Response: \(resString)")
  }

}
