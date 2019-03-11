//
//  Date+Extensions.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension Date {

  static func new(
    _ y: Int,
    _ m: Int,
    _ d: Int,
    time hh: Int = 0,
    _ mm: Int = 0,
    _ ss: Int = 0,
    _ ms: Int = 0,
    timeZone: TimeZone = .current) -> Date {

    let cal = Calendar(identifier: .gregorian)
    let components = DateComponents(
      calendar: cal,
      timeZone: timeZone,
      year: y,
      month: m,
      day: d,
      hour: hh,
      minute: mm,
      second: ss,
      nanosecond: (ms * 1_000_000) // milliseconds to nanoseconds
    )
    return components.date ?? Date()
  }

}

extension TimeZone {

  static var utc: TimeZone {
    return TimeZone(secondsFromGMT: 0) ?? .current
  }

}
