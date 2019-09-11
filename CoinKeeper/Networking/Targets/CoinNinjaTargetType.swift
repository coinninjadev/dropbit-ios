//
//  CoinNinjaTargetType.swift
//  DropBit
//
//  Created by Ben Winters on 10/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

protocol CoinNinjaTargetType: TargetType {

  associatedtype ResponseType: ResponseDecodable

  /// The first component of the target-specific path, e.g. "wallet", "user"
  /// Should not begin with a "/"
  var basePath: String { get }

  /// The remainder of the path following the basePath
  /// Should not begin with a "/"
  var subPath: String? { get }

  /// This gives the target the opportunity to translate the status code
  /// into a CKNetworkError that is more specific to its context.
  /// There is a default implementation which references `defaultNetworkError()`.
  func networkError(for moyaError: MoyaError) -> CKNetworkError?

}

extension CoinNinjaTargetType {

  // MARK: - Default implementations for TargetType

  public var baseURL: URL {
    #if DEBUG
//    return URL(string: "https://api.dev.coinninja.net/api/v1")!
    return URL(string: "https://api.test.coinninja.net/api/v1")!
    #else
    return URL(string: "https://api.coinninja.com/api/v1")!
    #endif
  }

  public var path: String {
    if let sPath = subPath {
      return basePath + "/" + sPath
    } else {
      return basePath
    }
  }

  public var thunderdomeBasePath: String {
    return CoinNinjaProvider.thunderdomeBasePath
  }

  public var sampleData: Data {
    return ResponseType.sampleData
  }

  public var validationType: ValidationType {
    return .successCodes
  }

  /// For most targets, the headers should be provided by the HeaderDelegate
  public var headers: [String: String]? {
    return nil
  }

  func networkError(for moyaError: MoyaError) -> CKNetworkError? {
    return defaultNetworkError(for: moyaError)
  }

  // MARK: - Helper methods for conforming targets

  func defaultNetworkError(for moyaError: MoyaError) -> CKNetworkError? {
    guard let statusCode = moyaError.response?.statusCode else {
      return CKNetworkError.reachabilityFailed(moyaError)
    }

    if case .objectMapping = moyaError {
      return CKNetworkError.decodingFailed(type: String(describing: ResponseType.self))
    }

    switch statusCode {
    case 400: return .badResponse
    case 401: return .unauthorized
    case 404: return .recordNotFound
    case 409: return .serverConflict
    case 429: return .rateLimitExceeded
    case 500: return .unknownServerError(moyaError)
    default:  return nil
    }
  }

  var customEncoder: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
  }

  func errorResponse(for response: Response) -> CoinNinjaErrorResponse? {
    return try? JSONDecoder().decode(CoinNinjaErrorResponse.self, from: response.data)
  }

  /// Allows conforming targets to construct a query body
  func queryBody(for key: String, value: [String]) -> Data? {
    let jsonDict = [
      "query": [
        "terms": [
          key: value
        ]
      ]
    ]
    let encoder = JSONEncoder()
    let data = try? encoder.encode(jsonDict)
    return data
  }

  var messagesToUnverify: [String] {
    let errorsToUnverify: [NetworkErrorIdentifier] = [.recordNotFound, .deviceUUIDMismatch, .userIDMismatch]
    return errorsToUnverify.map { $0.rawValue }
  }

}
