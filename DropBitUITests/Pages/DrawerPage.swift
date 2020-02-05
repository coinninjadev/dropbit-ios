//
//  DrawerPage.swift
//  DropBitUITests
//
//  Created by Ben Winters on 1/22/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class DrawerPage: UITestPage {

  init(ifExists: AssertionWaitCompletion = nil) {
    super.init(page: .drawer(.page), assertionWait: .default, ifExists: ifExists)
  }

  @discardableResult
  func tapGetBitcoin() -> Self {
    let getBitcoinCell = app.cell(withId: .drawer(.getBitcoin))
    getBitcoinCell.tap()
    return self
  }

  @discardableResult
  func tapEarn() -> Self {
    let earnCell = app.cell(withId: .drawer(.earn))
    earnCell.tap()
    return self
  }

  @discardableResult
  func tapSettings() -> Self {
    let settingsCell = app.cell(withId: .drawer(.settings))
    settingsCell.tap()
    return self
  }

  @discardableResult
  func tapVerificationStatus() -> Self {
    let verifyCell = app.cell(withId: .drawer(.verify))
    verifyCell.tap()
    return self
  }

  @discardableResult
  func tapSpend() -> Self {
    let spendCell = app.cell(withId: .drawer(.spend))
    spendCell.tap()
    return self
  }

  @discardableResult
  func tapSupport() -> Self {
    let supportCell = app.cell(withId: .drawer(.support))
    supportCell.tap()
    return self
  }

  @discardableResult
  func closeDrawer() -> Self {
    let infoView = app.view(withId: .drawer(.versionInfo))
    infoView.tap()
    return self
  }

}
