//
//  AlertManagerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import XCTest

class AlertManagerTests: XCTestCase {
  var sut: AlertManager!

  override func setUp() {
    super.setUp()
    let networkManager = NetworkManager(persistenceManager: PersistenceManager(),
                                        analyticsManager: AnalyticsManager())
    let notificationManager = NotificationManager(permissionManager: PermissionManager(),
                                                  networkInteractor: networkManager)
    self.sut = AlertManager(notificationManager: notificationManager)
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  func testAskingForAlertControllerReturnsExpectedController() {
    let expectedTitle = "the title"
    let expectedDescription = "the description"
    let expectedStyle = AlertManager.AlertStyle.alert
    let config = self.fakeConfig()
    let expectedActionTitle = "OK now"

    let alertController = self.sut.alert(
      withTitle: expectedTitle,
      description: expectedDescription,
      image: nil,
      style: expectedStyle,
      actionConfigs: [config]
    )
    let action = alertController.actions.first

    XCTAssertEqual(alertController.displayTitle, expectedTitle, "displayTitle should have expected value")
    XCTAssertEqual(alertController.displayDescription, expectedDescription, "displayDescription should have expected value")
    XCTAssertEqual(action?.title, expectedActionTitle)
  }

  func fakeConfig() -> AlertActionConfigurationType {
    return AlertActionConfiguration(title: "OK now", style: .default, action: nil)
  }
}
