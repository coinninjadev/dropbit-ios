//
//  BackupRecoveryWordsCellTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class BackupRecoveryWordsCellTests: XCTestCase {
  var sut: BackupRecoveryWordsCell!

  override func setUp() {
    super.setUp()
    self.sut = BackupRecoveryWordsCell.nib().instantiate(withOwner: self, options: nil).first as? BackupRecoveryWordsCell
    self.sut.awakeFromNib()
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.wordLabel, "wordLabel should be connected")
    XCTAssertNotNil(self.sut.statusLabel, "statusLabel should be connected")
  }

  // MARK: initial state
  func testWordLabelInitialState() {
    XCTAssertEqual(self.sut.wordLabel.textColor, .darkBlueText, "wordLabel textColor should be darkBlueText")
  }

  func testStatusLabelInitialState() {
    XCTAssertEqual(self.sut.statusLabel.textColor, .darkGrayText, "statusLabel textColor should be grayText")
  }

  // MARK: load method
  func testLoadMethodPopulatesLabels() {
    let expectedWord = "jalapeno"
    let expectedStatus = "word 1 of 12"
    let data = BackupRecoveryWordCellData(word: expectedWord, currentIndex: 1, total: 12)

    self.sut.load(with: data)

    XCTAssertEqual(self.sut.wordLabel.text, expectedWord, "should populate wordLabel")
    XCTAssertEqual(self.sut.statusLabel.text, expectedStatus, "should populate statusLabel")
  }
}
