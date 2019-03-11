//
//  FloatingPoint+DegreeToRadians.swift
//  CoinKeeper
//
//  Created by Mitchell on 4/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

extension FloatingPoint {
  var degreesToRadians: Self { return self * .pi / 180 }
  var radiansToDegrees: Self { return self * 180 / .pi }
}
