//
//  MoyaResponse+ErrorMessage.swift
//  DropBit
//
//  Created by Ben Winters on 7/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya
import Alamofire

extension MoyaError {

  var errorMessage: String? {
    return response.flatMap { String(data: $0.data, encoding: .utf8)}
  }

  /// Returns the status code of the underlying AFError, if that is the type of the MoyaError
  var unacceptableStatusCode: Int? {
    if case let .underlying(uError, _) = self,
      let afError = uError as? AFError,
      case let .responseValidationFailed(reason) = afError,
      case let .unacceptableStatusCode(statusCode) = reason {
      return statusCode
    } else {
      return nil
    }
  }

}
