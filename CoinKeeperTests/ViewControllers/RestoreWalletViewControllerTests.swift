//
//  RestoreWalletViewControllerTests.swift
//  DropBitTests
//
//  Created by Mitchell on 7/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class RestoreWalletViewControllerTests: XCTestCase {
  var sut: RestoreWalletViewController!

  override func setUp() {
    super.setUp()
    self.sut = RestoreWalletViewController.makeFromStoryboard()
    _ = self.sut.view
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets are connected
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.titleLabel, "titleLabel should be connected")
    XCTAssertNotNil(self.sut.detailLabel, "detailLabel should be connected")
    XCTAssertNotNil(self.sut.selectWordLabel, "selectWordLabel should be connected")
    XCTAssertNotNil(self.sut.wordTextField, "wordTextField should be connected")
    XCTAssertNotNil(self.sut.wordCountLabel, "wordCountLabel should be connected")
    XCTAssertNotNil(self.sut.wordButtonOne, "wordButtonOne should be connected")
    XCTAssertNotNil(self.sut.wordButtonTwo, "wordButtonTwo should be connected")
    XCTAssertNotNil(self.sut.wordButtonThree, "wordButtonThree should be connected")
    XCTAssertNotNil(self.sut.wordButtonFour, "wordButtonFour should be connected")
    XCTAssertNotNil(self.sut.invalidWordButton, "invalidWordButton should be connected")
  }

  func testWordButtonsContainActions() {
    let buttonOneActions = self.sut.wordButtonOne.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let buttonTwoActions = self.sut.wordButtonTwo.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let buttonThreeActions = self.sut.wordButtonThree.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let buttonFourActions = self.sut.wordButtonFour.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let actionSelector = #selector(RestoreWalletViewController.buttonWasPressed)
    XCTAssertTrue(buttonOneActions.contains(actionSelector.description), "wordButtonOne should contain action")
    XCTAssertTrue(buttonTwoActions.contains(actionSelector.description), "wordButtonTwo should contain action")
    XCTAssertTrue(buttonThreeActions.contains(actionSelector.description), "wordButtonThree should contain action")
    XCTAssertTrue(buttonFourActions.contains(actionSelector.description), "wordButtonFour should contain action")
  }

  func testInvalidWordButtonContainActions() {
    let invalidWordButtonActions = self.sut.invalidWordButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let actionSelector = #selector(RestoreWalletViewController.invalidButtonWasTouched)
    XCTAssertTrue(invalidWordButtonActions.contains(actionSelector.description), "wordButtonOne should contain action")
  }

  func testWordButtonAction() {
    let testWord = "weasel"
    self.sut.wordTextField.text = testWord
    self.sut.wordButtonOne.setTitle(testWord, for: .normal)
    self.sut.buttonWasPressed(self.sut.wordButtonOne)

    XCTAssertEqual(self.sut.wordTextField.text, "", "text field text should be an empty string")
    XCTAssertEqual(self.sut.wordButtonOne.isHidden, true, "wordButtonOne should be hidden")
  }

  func testInvalidButtonAction() {
    let testWord = "weasel"
    self.sut.wordTextField.text = testWord
    self.sut.wordButtonOne.setTitle(testWord, for: .normal)
    self.sut.invalidButtonWasTouched()

    XCTAssertEqual(self.sut.wordTextField.text, "", "text field text should be an empty string")
    XCTAssertEqual(self.sut.wordButtonOne.isHidden, true, "wordButtonOne should be hidden")
  }

  func testInvalidButtonContainsAction() {
    let invalidWordButtonActions = self.sut.invalidWordButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let actionSelector = #selector(RestoreWalletViewController.invalidButtonWasTouched)
    XCTAssertTrue(invalidWordButtonActions.contains(actionSelector.description), "invalidWordButton should contain action")
  }
}
