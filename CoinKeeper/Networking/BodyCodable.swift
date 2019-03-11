//
//  BodyCodable.swift
//  DropBit
//
//  Created by Ben Winters on 10/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/// Useful for encoding an example request body
protocol BodyEncodable: Encodable {
  static var sampleJSON: String { get }
}
