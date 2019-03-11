//
//  LaunchType.swift
//  CoinKeeper
//
//  Created by BJ Miller on 7/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

/// Enum defining the type of launch, whether the user initiated the app launch, or if due to a background fetch.
///
/// - userInitiated: The user actively opened the application.
/// - backgroundFetch: The app was launched due to a background fetch.
enum LaunchType {
  case userInitiated
  case backgroundFetch

  mutating func reset() {
    self = .userInitiated
  }
}
