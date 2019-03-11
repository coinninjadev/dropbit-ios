//
//  DevicesTarget.swift
//  DropBit
//
//  Created by Ben Winters on 10/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Moya

public enum DevicesTarget: CoinNinjaTargetType {
  typealias ResponseType = DeviceResponse

  case create(CreateDeviceBody)
  case get(String)

  var basePath: String {
    return "devices"
  }

  var subPath: String? {
    switch self {
    case .create:             return nil
    case .get(let device):    return device
    }
  }

  public var method: Method {
    switch self {
    case .create: return .post
    case .get:    return .get
    }
  }

  public var task: Task {
    switch self {
    case .create(let body): return .requestCustomJSONEncodable(body, encoder: customEncoder)
    case .get: return .requestPlain
    }
  }

  var sampleJSON: String {
    switch self {
    case .create:
      return """
      {
      "application": "DropBit",
      "platform": "ios",
      "uuid": "8112d3a1-1ae1-4b8e-a443-8d4ff66f472b"
      }
      """
    case .get:
      return """
      {
      "id": "158a4cf9-0362-4636-8c68-ed7a98a7f345",
      "created_at": 1531921356,
      "updated_at": 1531921356,
      "application": "DropIt",
      "platform": "ios",
      "uuid": "998207d6-5b1e-47c9-84e9-895f52a1b455"
      }
      """
    }
  }

}
