//
//  RecoveryWordsIntroViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 11/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class RecoveryWordsIntroViewControllerTests: XCTestCase {

  var sut: RecoveryWordsIntroViewController!
  // swiftlint:disable:next weak_delegate
  var mockDelegate: MockRecoveryWordsIntroViewControllerDelegate!

  override func setUp() {
    mockDelegate = MockRecoveryWordsIntroViewControllerDelegate()
    self.sut = RecoveryWordsIntroViewController.makeFromStoryboard()
    self.sut.delegate = mockDelegate
    _ = sut.view
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.titleLabel, "titleLabel should be connected")
    XCTAssertNotNil(self.sut.subtitle1Label, "subtitle1Label should be connected")
    XCTAssertNotNil(self.sut.subtitle2Label, "subtitle2Label should be connected")
    XCTAssertNotNil(self.sut.writeImageView, "writeImageView should be connected")
    XCTAssertNotNil(self.sut.restoreInfoLabel, "restoreInfoLabel should be connected")
    XCTAssertNotNil(self.sut.estimatedTimeLabel, "estimatedTimeLabel should be connected")
    XCTAssertNotNil(self.sut.proceedButton, "proceedButton should be connected")
    XCTAssertNotNil(self.sut.skipButton, "skipButton should be connected")
  }

  // MARK: buttons contain actions
  func testProceedButtonContainsAction() {
    let actions = self.sut.proceedButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let proceedSelector = #selector(RecoveryWordsIntroViewController.proceedButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(proceedSelector), "proceedButton should contain action")
  }

  func testSkipButtonContainsAction() {
    let actions = self.sut.skipButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let skipSelector = #selector(RecoveryWordsIntroViewController.skipButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(skipSelector), "skipButton should contain action")
  }

  // MARK: actions produce results
  func testProceedButtonTellsDelegateToProceedToBackup() {
    sut.proceedButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockDelegate.wasAskedToBackupRecoveryWords)
  }

  func testSkipButtonTellsDelegateToSkipBackup() {
    sut.skipButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockDelegate.wasAskedToSkipRecoveryWords)
  }

}
