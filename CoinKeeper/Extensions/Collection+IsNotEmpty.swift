//
//  Collection+IsNotEmpty.swift
//  DropBit
//
//  Created by Ben Winters on 4/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension BidirectionalCollection {

  var isNotEmpty: Bool {
    return !isEmpty
  }

}

extension SetAlgebra {
  var isNotEmpty: Bool {
    return !isEmpty
  }
}
