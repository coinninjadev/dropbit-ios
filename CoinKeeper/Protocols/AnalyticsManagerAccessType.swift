//
//  AnalyticsManagerAccessType.swift
//  DropBit
//
//  Created by Mitchell Malleo on 10/9/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol AnalyticsManagerAccessType: class {
  func viewControllerShouldTrackEvent(event: AnalyticsManagerEventType)
  func viewControllerShouldTrackEvent(event: AnalyticsManagerEventType, with values: [AnalyticsEventValue])

  func viewControllerShouldTrackProperty(property: MixpanelProperty)
}
