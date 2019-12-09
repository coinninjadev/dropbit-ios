//
//  FeatureManager.swift
//  DropBit
//
//  Created by Ben Winters on 12/9/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import JustTweak

protocol FeatureManagerType {

}

struct FeatureManager: FeatureManagerType {

  let coordinator: TweakManager

  init(userDefaults: UserDefaults) {
    let userDefaultsConfiguration = UserDefaultsConfiguration(userDefaults: userDefaults)

    // priority is defined by the order in the configurations array (from highest to lowest)
    coordinator = TweakManager(configurations: [userDefaultsConfiguration])
  }

}
