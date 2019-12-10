//
//  FeatureConfigurable.swift
//  DropBit
//
//  Created by Ben Winters on 12/10/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol FeatureConfigDataSource: AnyObject {
  func currentConfig() -> FeatureConfig
}

///Conforming objects (view controllers), need to set a datasource
///and call subscribeToFeatureConfigurationUpdates() during viewDidLoad()
protocol FeatureConfigurable: AnyObject {

  var featureConfigNotificationToken: NotificationToken? { get set }
  var featureConfigDataSource: FeatureConfigDataSource? { get }

  ///Implementation should get latest config from `featureConfigDataSource` and reload itself
  func reloadFeatureConfigurableView()

}

extension FeatureConfigurable {

  func subscribeToFeatureConfigurationUpdates() {
    featureConfigNotificationToken = CKNotificationCenter.subscribe(
      key: .didUpdateFeatureConfig, object: nil, queue: nil, using: { [weak self] _ in
        self?.reloadFeatureConfigurableView()
    })
  }
}

struct FeatureConfig {

  enum Key: String {
    case referrals
  }

  private var enabledFeatures: [Key] = []

  func shouldEnable(_ feature: Key) -> Bool {
    return enabledFeatures.contains(feature)
  }

  func shouldDisable(_ feature: Key) -> Bool {
    return !shouldEnable(feature)
  }

  private func isEnabledByDefault(for key: Key) -> Bool {
    switch key {
    case .referrals:        return true
    }
  }

}

protocol FeatureConfigManagerType: AnyObject {
  func update(with response)
}
class FeatureConfigManager: FeatureConfigManagerType {

}
