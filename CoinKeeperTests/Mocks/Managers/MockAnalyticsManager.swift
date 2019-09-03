//
//  MockAnalyticsManager.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit

class MockAnalyticsManager: AnalyticsManagerType {
  func track(event: AnalyticsManagerEventType, with values: [AnalyticsEventValue]) {}

  var eventValueString: String?
  func track(event: AnalyticsManagerEventType, with value: AnalyticsEventValue?) {
    eventValueString = value?.value
  }

  func track(error: AnalyticsManagerErrorType, with message: String) {}
  func track(event: AnalyticsManagerEventType, with values: [JSONObject]?) {}
  func track(property: MixpanelProperty) {}

  var startWasCalled = false
  func start() {
    startWasCalled = true
  }

  func hideViews(views: [UIView]) {
  }

  func unhideViews(views: [UIView]) {
  }

  func optOut() {
  }

  func optIn() {
  }
}
