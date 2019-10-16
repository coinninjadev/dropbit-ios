//
//  AppCoordinator+AnalyticsMangerAccessType.swift
//  DropBit
//
//  Created by Mitchell Malleo on 10/9/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

extension AppCoordinator: AnalyticsManagerAccessType {

  func viewControllerShouldTrackEvent(event: AnalyticsManagerEventType) {
    viewControllerShouldTrackEvent(event: event, with: [])
  }

  func viewControllerShouldTrackEvent(event: AnalyticsManagerEventType, with values: [AnalyticsEventValue]) {
    analyticsManager.track(event: event, with: values)
  }

  func viewControllerShouldTrackProperty(property: MixpanelProperty) {
    analyticsManager.track(property: property)
  }
}
