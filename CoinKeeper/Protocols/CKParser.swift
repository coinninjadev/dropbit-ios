//
//  CKParser.swift
//  DropBit
//
//  Created by Mitchell Malleo on 1/20/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol CKParser {
  associatedtype Result
  func parse(_ string: String) throws -> Result?
}
