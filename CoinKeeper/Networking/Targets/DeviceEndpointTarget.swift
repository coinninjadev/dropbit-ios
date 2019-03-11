//
//  DeviceEndpointTarget.swift
//  DropBit
//
//  Created by Ben Winters on 10/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum DeviceEndpointTarget: CoinNinjaTargetType {
  typealias ResponseType = DeviceEndpointResponse

  case create(String, CreateDeviceEndpointBody)
  case delete(DeviceEndpointIds)
  case getEndpoints(String)

  var basePath: String {
    return "devices"
  }

  var subPath: String? {
    switch self {
    case .create(let deviceId, _), .getEndpoints(let deviceId):
      return "\(deviceId)/endpoints"
    case .delete(let ids):
      return "\(ids.serverDevice)/endpoints/\(ids.endpoint)"
    }
  }

  public var method: Method {
    switch self {
    case .create:       return .post
    case .delete:       return .delete
    case .getEndpoints: return .get
    }
  }

  public var task: Task {
    switch self {
    case .create(_, let body):
      return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .getEndpoints, .delete:
      return .requestPlain
    }
  }

}
