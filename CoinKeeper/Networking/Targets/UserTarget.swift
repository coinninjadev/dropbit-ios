//
//  UserTarget.swift
//  DropBit
//
//  Created by Ben Winters on 9/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum UserTarget: CoinNinjaTargetType {
  typealias ResponseType = UserResponse

  case create(CreateUserHeaders, UserIdentityBody)
  case get
  case verify(String, VerifyUserBody) //userID for headers, body
  case updateIsPrivate(Bool)

  /// Headers reference UserID returned by server instead of local persistence
  case resendVerification(DefaultRequestHeaders, UserIdentityBody)

  case deleteIdentity(String)
}

extension UserTarget {

  var basePath: String {
    return "user"
  }

  var subPath: String? {
    switch self {
    case .verify: return "verify"
    case .resendVerification: return "resend"
    case .deleteIdentity(let identity): return "identity/\(identity)"
    default: return nil
    }
  }

  public var method: Method {
    switch self {
    case .get:                  return .get
    case .create,
         .verify,
         .resendVerification:   return .post
    case .deleteIdentity:       return .delete
    case .updateIsPrivate:      return .patch
    }
  }

  public var task: Task {
    switch self {
    case .create(_, let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)

    case .get, .deleteIdentity:
      return .requestPlain

    case .verify(_, let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .resendVerification(_, let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .updateIsPrivate(let isPrivate):
      let body = UserPatchPrivateBody(private: isPrivate)
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    }
  }

  public var validationType: ValidationType {
    switch self {
    case .create:
      return .customCodes([201, 501])
    case .resendVerification:
      return .customCodes([200, 501])
    case .deleteIdentity:
      return .customCodes([204, 404])
    default:
      return .successCodes
    }
  }

  public var headers: [String: String]? {
    switch self {
    case .create(let headers, _):
      return headers.dictionary

    case .verify(let userId, _):
      return CNHeaderParameter.dictionary(withKeyValues: [.authUserId: userId])

    case .resendVerification(let headers, _):
      return headers.dictionary

    default:
      return nil
    }
  }

  func networkError(for moyaError: MoyaError) -> CKNetworkError? {
    let defaultError = defaultNetworkError(for: moyaError)
    guard let statusCode = moyaError.unacceptableStatusCode, let response = moyaError.response else {
      return defaultError
    }

    switch statusCode {
    case 200:
      return .recordAlreadyExists(response)
    case 401:
      if case .get = self, moyaError.responseDescription.containsAny(messagesToUnverify) {
        return .shouldUnverify(moyaError, .user)
      } else {
        return defaultError
      }
    case 424:
      return countryCodeDisabledError() ?? defaultError
    case 501:
      switch self {
      case .create, .resendVerification:
        return .twilioError(response)
      default:
        return defaultError
      }
    default:
      return defaultError
    }
  }

  private func countryCodeDisabledError() -> CKNetworkError? {
    switch self {
    case .create, .resendVerification:
      return .countryCodeDisabled
    default:
      return nil
    }
  }

}
