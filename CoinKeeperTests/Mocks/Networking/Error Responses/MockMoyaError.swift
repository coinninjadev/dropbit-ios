//
//  MockMoyaError.swift
//  DropBitTests
//
//  Created by Ben Winters on 12/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya
import Alamofire

struct MockMoyaError {

  static func unacceptableStatusCode(code: Int, responseData: Data) -> MoyaError {
    let response = Response(statusCode: code, data: responseData)
    let failureReason: AFError.ResponseValidationFailureReason = .unacceptableStatusCode(code: code)
    let afError = AFError.responseValidationFailed(reason: failureReason)
    return MoyaError.underlying(afError, response)
  }

}
