//
//  CKSystemError.swift
//  DropBit
//
//  Created by Ben Winters on 11/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum CKSystemError: Error, LocalizedError {

  case missingValue(key: String)

}
