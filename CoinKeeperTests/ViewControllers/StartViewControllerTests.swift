//
// Created by BJ Miller on 2/1/18.
// Copyright (c) 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import UIKit

class StartViewControllerTests: XCTestCase {

  var sut: StartViewController!

  override func setUp() {
    super.setUp()
    self.sut = StartViewController.makeFromStoryboard()
    _ = self.sut.view
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.newWalletButton, "newWalletButton should be connected")
    XCTAssertNotNil(self.sut.restoreWalletButton, "restoreWalletButton should be connected")
    XCTAssertNotNil(self.sut.blockchainImage, "blockchainImage should be connected")
    XCTAssertNotNil(self.sut.logoImage, "logoImage should be connected")
    XCTAssertNotNil(self.sut.logoImageVerticalConstraint, "logoImageVerticalConstraint should be connected")
    XCTAssertNotNil(self.sut.welcomeLabel, "welcomeLabel should be connected")
    XCTAssertNotNil(self.sut.welcomeBGView, "welcomeBGView should be connected")
    XCTAssertNotNil(self.sut.welcomeBGViewTopConstraint, "welcomeBGViewTopConstraint should be connected")
    XCTAssertNotNil(self.sut.animatableViews, "animatableViews should be connected")
  }

  // MARK: initial state
  func testCreateWalletButtonInitialState() {
    let expectedText = "NEW WALLET"
    let expectedColor = UIColor.lightBlueTint

    XCTAssertEqual(self.sut.newWalletButton.title(for: .normal), expectedText, "newWalletButton text should match")
    XCTAssertEqual(self.sut.newWalletButton.currentTitleColor, expectedColor, "newWalletButton color should match")
    XCTAssertTrue(self.sut.newWalletButton.isHidden, "newWalletButton should be hidden")
    XCTAssertEqual(self.sut.newWalletButton.alpha, 0, "newWalletButton alpha should be 0")

    // trigger new animated state
    self.sut.viewDidAppear(false)
    XCTAssertFalse(self.sut.newWalletButton.isHidden, "newWalletButton should not be hidden")
    XCTAssertEqual(self.sut.newWalletButton.alpha, 1, "newWalletButton alpha should be 1")
  }

  func testRestoreWalletButtonInitialState() {
    let expectedText = "Restore Wallet"
    let expectedColor = UIColor.darkBlueText

    let buttonTitleText = self.sut.restoreWalletButton.attributedTitle(for: .normal)?.string ?? ""
    XCTAssertTrue(buttonTitleText.contains(expectedText), "restoreWalletButton text should match")
    XCTAssertEqual(self.sut.restoreWalletButton.titleLabel?.textColor, expectedColor, "restoreWalletButton color should match")
    XCTAssertTrue(self.sut.restoreWalletButton.isHidden, "restoreWalletButton should be hidden")
    XCTAssertEqual(self.sut.restoreWalletButton.alpha, 0, "restoreWalletButton alpha should be 0")

    // trigger new animated state
    self.sut.viewDidAppear(false)
    XCTAssertFalse(self.sut.restoreWalletButton.isHidden, "restoreWalletButton should not be hidden")
    XCTAssertEqual(self.sut.restoreWalletButton.alpha, 1, "restoreWalletButton alpha should be 1")
  }

  func testBlockchainImageInitialState() {
    let expectedData = UIImage(named: "blockchainImage")?.pngData()
    let actualData = self.sut.blockchainImage?.image?.pngData()

    XCTAssertEqual(actualData, expectedData)
  }

  func testLogoImageInitialState() {
    let expectedData = UIImage(named: "logo")?.pngData()
    let actualData = self.sut.logoImage?.image?.pngData()

    XCTAssertEqual(actualData, expectedData)
  }

  func testLogoImageVerticalConstraint() {
    let initialExpectedValue = CGFloat(0)
    XCTAssertEqual(self.sut.logoImageVerticalConstraint.constant, initialExpectedValue)

    // when
    let offset = ((self.sut.welcomeBGView.frame.height / 2.0) * -1) -
      (self.sut.welcomeBGViewTopConstraint.constant / 2.0)
    self.sut.viewDidAppear(false)
    XCTAssertEqual(self.sut.logoImageVerticalConstraint.constant, offset)
  }

  func testWelcomeLabelInitialState() {
    let expectedText = "The simplest way to send and receive Bitcoin"
    XCTAssertEqual(self.sut.welcomeLabel.text, expectedText)
  }

  func testWelcomeBGViewInitialState() {
    let expectedColor = UIColor.clear

    XCTAssertEqual(self.sut.welcomeBGView.backgroundColor, expectedColor, "welcomeBGView backgroundColor should be clear")
    XCTAssertTrue(self.sut.welcomeBGView.isHidden, "welcomeBGView should be initially hidden")
    XCTAssertEqual(self.sut.welcomeBGView.alpha, 0, "welcomeBGView alpha should initially be 0")

    // when
    self.sut.viewDidAppear(false)
    XCTAssertFalse(self.sut.welcomeBGView.isHidden, "welcomeBGView should be eventually show")
    XCTAssertEqual(self.sut.welcomeBGView.alpha, 1, "welcomeBGView alpha should initially be 1")
  }

  func testWelcomeBGViewTopConstraintInitialState() {
    let expectedOffset = CGFloat(23)
    XCTAssertTrue(self.sut.welcomeBGViewTopConstraint.isActive, "welcomeBGViewTopConstraint should be active")
    XCTAssertEqual(self.sut.welcomeBGViewTopConstraint.constant, expectedOffset, "welcomeBGViewTopConstraint offset should be 23")
  }

  // MARK: buttons contain actions
  func testCreateWalletButtonContainsAction() {
    let actions = self.sut.newWalletButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let newWalletSelector = #selector(StartViewController.newWalletButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(newWalletSelector), "newWalletButton should contain action")
  }

  func testRestoreWalletButtonContainsAction() {
    let actions = self.sut.restoreWalletButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let restoreSelector = #selector(StartViewController.restoreWalletButtonTapped).description
    XCTAssertTrue(actions.contains(restoreSelector), "restoreWalletButton should contain action")
  }

  // MARK: actions produce results
  func testCreateWalletButtonActionTellsCoordinator() {
    let mockCoordinator = MockCoordinator()
    self.sut.generalCoordinationDelegate = mockCoordinator

    self.sut.newWalletButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.createWalletWasCalled, "createWallet should be called")
  }

  func testRestoreWalletButtonActionTellsCoordinator() {
    let mockCoordinator = MockCoordinator()
    self.sut.generalCoordinationDelegate = mockCoordinator

    self.sut.restoreWalletButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.restoreWalletWasCalled, "restoreWallet should be called")
  }

  class MockCoordinator: StartViewControllerDelegate {
    var appEnteredActiveStateWasCalled = false
    func requireAuthenticationIfNeeded(whenAuthenticated: @escaping () -> Void) {
      appEnteredActiveStateWasCalled = true
    }

    func requireAuthenticationIfNeeded() {
      appEnteredActiveStateWasCalled = true
    }

    func clearPin() {}
    func claimInvite() {}

    var createWalletWasCalled = false
    var restoreWalletWasCalled = false

    func createWallet() {
      createWalletWasCalled = true
    }

    func restoreWallet() {
      restoreWalletWasCalled = true
    }
  }
}
