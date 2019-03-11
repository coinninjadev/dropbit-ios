//
//  VerifyRecoveryWordsViewModelTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import XCTest

class VerifyRecoveryWordsViewModelTests: XCTestCase {
  var sut: VerifyRecoveryWordsViewModel!
  // swiftlint:disable weak_delegate
  var mockResultDelegate: MockVerifyRecoveryWordsResultDelegate!
  var mockSelectionDelegate: MockVerifyRecoveryWordsSelectionDelegate!
  // swiftlint:enable weak_delegate

  override func setUp() {
    super.setUp()
    mockResultDelegate = MockVerifyRecoveryWordsResultDelegate()
    self.sut = VerifyRecoveryWordsViewModel(words: TestHelpers.fakeWords(), resultDelegate: mockResultDelegate)
    mockSelectionDelegate = MockVerifyRecoveryWordsSelectionDelegate()
  }

  override func tearDown() {
    self.sut = nil
    mockResultDelegate = nil
    mockSelectionDelegate = nil
    super.tearDown()
  }

  // MARK: possible words
  func testDataObjectsForVerificationGetsProperResults() {
    let results = self.sut.dataObjectsForVerification(withDelegate: mockSelectionDelegate)

    XCTAssertEqual(results.count, 2, "dataObjects should return 2 items")
    XCTAssertNotEqual(results.first?.selectedIndex, results.last?.selectedIndex, "the two selected indexes should not be equal")

    let expectedCount = 5
    XCTAssertEqual(results.first?.possibleWords.count, expectedCount, "there should be 5 possible words in first set")
    XCTAssertEqual(results.last?.possibleWords.count, expectedCount, "there should be 5 possible words in last set")

    XCTAssertTrue(Set(results[0].possibleWords).isSubset(of: Set(TestHelpers.fakeWords())), "possibleWords should be a subset of all words")
    XCTAssertTrue(Set(results[1].possibleWords).isSubset(of: Set(TestHelpers.fakeWords())), "possibleWords should be a subset of all words")

    let expectedFirstWord = results.first
      .flatMap { $0.selectedIndex }
      .flatMap { TestHelpers.fakeWords()[$0] } ?? ""
    XCTAssertTrue(results.first?.possibleWords.contains(expectedFirstWord) ?? false, "should contain selected word")

    XCTAssertTrue(results.first?.selectionDelegate === mockSelectionDelegate, "maintains reference to selection delegate")

    let expectedLastWord = results.last
      .flatMap { $0.selectedIndex }
      .flatMap { TestHelpers.fakeWords()[$0] } ?? ""
    XCTAssertTrue(results.last?.possibleWords.contains(expectedLastWord) ?? false, "should contain selected word")

    XCTAssertTrue(results.last?.selectionDelegate === mockSelectionDelegate, "maintains reference to selection delegate")
  }

  // MARK: check match
  func testCallingCheckMatchFirstTimeTellsDelegate() {
    let cellData = self.sut.dataObjectsForVerification(withDelegate: mockSelectionDelegate)[0]
    let word = cellData.words[cellData.selectedIndex]

    self.sut.checkMatch(forWord: word, cellData: cellData)

    XCTAssertTrue(mockResultDelegate.firstMatchFoundWasCalled, "should tell delegate first match was found")
  }

  func testCallingCheckMatchSecondTimeTellsDelegate() {
    let cellData = self.sut.dataObjectsForVerification(withDelegate: mockSelectionDelegate)[1]
    let word = cellData.words[cellData.selectedIndex]

    self.sut.checkMatch(forWord: word, cellData: cellData)

    XCTAssertTrue(mockResultDelegate.secondMatchFoundWasCalled, "should tell delegate first match was found")
  }

  // MARK: errors
  func testHandlingFirstErrorTellsDelegate() {
    let cellData = self.sut.dataObjectsForVerification(withDelegate: mockSelectionDelegate)[0]
    let word = "this_is_not_a_real_bitcoin_mnemonic_word"

    self.sut.checkMatch(forWord: word, cellData: cellData)

    XCTAssertTrue(mockResultDelegate.errorFoundWasCalled, "getting error should tell delegate")
  }

  func testHandlingThirdErrorTellsDelegateFatalErrorWasFound() {
    let cellData = self.sut.dataObjectsForVerification(withDelegate: mockSelectionDelegate)[0]
    let word = "this_is_not_a_real_bitcoin_mnemonic_word"

    3.times { self.sut.checkMatch(forWord: word, cellData: cellData) }

    XCTAssertTrue(mockResultDelegate.fatalErrorFoundWasCalled, "third failure should trigger fatal error")
  }

  func testTwoErrorsOnEachWordDoesNotAccumulateErrors() {
    let firstCellData = self.sut.dataObjectsForVerification(withDelegate: mockSelectionDelegate)[0]
    let secondCellData = self.sut.dataObjectsForVerification(withDelegate: mockSelectionDelegate)[1]
    let badWord = "this_is_not_a_real_bitcoin_mnemonic_word"
    let word = firstCellData.words[firstCellData.selectedIndex]

    self.sut.checkMatch(forWord: badWord, cellData: firstCellData)  // bad
    self.sut.checkMatch(forWord: badWord, cellData: firstCellData)  // bad
    self.sut.checkMatch(forWord: word, cellData: firstCellData)     // good

    self.sut.checkMatch(forWord: badWord, cellData: secondCellData) // bad
    self.sut.checkMatch(forWord: badWord, cellData: secondCellData) // bad

    XCTAssertFalse(mockResultDelegate.fatalErrorFoundWasCalled, "should not accumulate error count for fatal error")
  }

}
