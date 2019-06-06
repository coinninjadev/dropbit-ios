//
//  VerifyRecoveryWordCellTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class VerifyRecoveryWordCellTests: XCTestCase {
  var sut: VerifyRecoveryWordCell!

  override func setUp() {
    super.setUp()
    self.sut = VerifyRecoveryWordCell.nib().instantiate(withOwner: self, options: nil).first as? VerifyRecoveryWordCell
    self.sut.awakeFromNib()
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.wordLabelBackgroundView, "wordLabelBackgroundView should be connected")
    XCTAssertNotNil(self.sut.spacerView, "spacerView should be connected")
    XCTAssertNotNil(self.sut.wordLabel, "wordLabel should be connected")
    XCTAssertNotNil(self.sut.word1Button, "word1Button should be connected")
    XCTAssertNotNil(self.sut.word2Button, "word2Button should be connected")
    XCTAssertNotNil(self.sut.word3Button, "word3Button should be connected")
    XCTAssertNotNil(self.sut.word4Button, "word4Button should be connected")
    XCTAssertNotNil(self.sut.word5Button, "word5Button should be connected")
  }

  // MARK: initial state
  func testWordLabelBackgroundViewInitialState() {
    let color = UIColor.extraLightGrayBackground
    XCTAssertEqual(self.sut.wordLabelBackgroundView.backgroundColor, color, "wordLabelBackgroundView color should be set")
  }

  func testSpacerViewInitialState() {
    XCTAssertEqual(self.sut.spacerView.backgroundColor, .clear, "spacerView backgroundColor should be clear")
  }

  // MARK: loading cell
  func testLoadingCellPopulatesOutlets() {
    let expectedWordLabelText = "Select word 7"
    let selectedIndex = 6
    let mockSelectionDelegate = MockVerifyRecoveryWordsSelectionDelegate()
    let possibleWords = ["one", "two", "three", "four", "five"]
    let expectedWords = possibleWords.map { $0.uppercased() }
    let cellData = VerifyRecoveryWordCellData(
      words: TestHelpers.fakeWords(),
      selectedIndex: selectedIndex,
      possibleWords: possibleWords,
      selectionDelegate: mockSelectionDelegate
    )

    self.sut.load(with: cellData)

    XCTAssertEqual(self.sut.wordLabel.text, expectedWordLabelText, "wordLabel should be populated")
    XCTAssertEqual(self.sut.word1Button.title(for: .normal), expectedWords[0], "word1Button should show first random word")
    XCTAssertEqual(self.sut.word2Button.title(for: .normal), expectedWords[1], "word2Button should show second random word")
    XCTAssertEqual(self.sut.word3Button.title(for: .normal), expectedWords[2], "word3Button should show third random word")
    XCTAssertEqual(self.sut.word4Button.title(for: .normal), expectedWords[3], "word4Button should show fourth random word")
    XCTAssertEqual(self.sut.word5Button.title(for: .normal), expectedWords[4], "word5Button should show fifth random word")
  }

  // MARK: buttons contain actions
  private let expectedButtonSelector = #selector(VerifyRecoveryWordCell.buttonTapped(_:)).description

  func testWord1ButtonContainsAction() {
    let actions = self.sut.word1Button.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    XCTAssertTrue(actions.contains(expectedButtonSelector))
  }

  func testWord2ButtonContainsAction() {
    let actions = self.sut.word2Button.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    XCTAssertTrue(actions.contains(expectedButtonSelector))
  }

  func testWord3ButtonContainsAction() {
    let actions = self.sut.word3Button.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    XCTAssertTrue(actions.contains(expectedButtonSelector))
  }

  func testWord4ButtonContainsAction() {
    let actions = self.sut.word4Button.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    XCTAssertTrue(actions.contains(expectedButtonSelector))
  }

  func testWord5ButtonContainsAction() {
    let actions = self.sut.word5Button.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    XCTAssertTrue(actions.contains(expectedButtonSelector))
  }

  // MARK: actions produce results
  func testButtonTappedWithValidDataProducesResults() {
    let mockSelectionDelegate = MockVerifyRecoveryWordsSelectionDelegate()
    let cellData = VerifyRecoveryWordCellData(
      words: TestHelpers.fakeWords(),
      selectedIndex: 0,
      possibleWords: ["one"],
      selectionDelegate: mockSelectionDelegate
    )

    self.sut.load(with: cellData)

    let expectedWord = "foo"
    let button = UIButton(type: .system)
    button.setTitle(expectedWord, for: .normal)
    self.sut.buttonTapped(button)

    XCTAssertTrue(mockSelectionDelegate.wasAskedForDidSelectWord, "should tell delegate that a button was tapped")
    XCTAssertEqual(mockSelectionDelegate.selectedWord, expectedWord, "should send button title to delegate")
    XCTAssertEqual(mockSelectionDelegate.selectedCellData, cellData, "should send cellData to delegate")
  }

  func testButtonTappedWithInvalidDataProducesResults() {
    let mockSelectionDelegate = MockVerifyRecoveryWordsSelectionDelegate()
    let cellData = VerifyRecoveryWordCellData(
      words: TestHelpers.fakeWords(),
      selectedIndex: 0,
      possibleWords: ["one"],
      selectionDelegate: mockSelectionDelegate
    )

    self.sut.load(with: cellData)

    let button = UIButton(type: .system)
    button.setTitle(nil, for: .normal)
    self.sut.buttonTapped(button)

    XCTAssertFalse(mockSelectionDelegate.wasAskedForDidSelectWord, "should not tell delegate that a button was tapped")
  }
}
