//
//  VerifyRecoveryWordsViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class VerifyRecoveryWordsViewControllerTests: XCTestCase {
  var sut: VerifyRecoveryWordsViewController!
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    super.setUp()

    self.sut = VerifyRecoveryWordsViewController.makeFromStoryboard()
    mockCoordinator = MockCoordinator()
    self.sut.delegate = mockCoordinator
  }

  override func tearDown() {
    self.sut = nil
    self.mockCoordinator = nil
    super.tearDown()
  }

  /// Needed to delay the loading of the view to simulate view lifecycle WRT dependency injection sequences
  private func loadView() {
    _ = self.sut.view
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    loadView()
    XCTAssertNotNil(self.sut.titleLabel, "titleLabel should be connected")
    XCTAssertNotNil(self.sut.subtitleLabel, "subtitleLabel should be connected")
    XCTAssertNotNil(self.sut.verificationCollectionView, "verificationCollectionView should be connected")
  }

  // MARK: initial state
  func testTitleLabelInitialState() {
    loadView()
    let expectedText = "Verify Words"
    XCTAssertEqual(self.sut.titleLabel.text, expectedText)
  }

  func testSubtitleLabelInitialState() {
    loadView()
    let expectedText = "Select the correct word."
    XCTAssertEqual(self.sut.subtitleLabel.text, expectedText)
  }

  func testVerificationCollectionViewInitialState() {
    loadView()
    XCTAssertFalse(self.sut.verificationCollectionView.isScrollEnabled, "scrolling should be disabled")
    XCTAssertEqual(self.sut.verificationCollectionView.backgroundColor, UIColor.clear, "backgroundColor should be clear")
    XCTAssertFalse(self.sut.verificationCollectionView.showsHorizontalScrollIndicator, "should not show horizontal scroll indicator")
  }

  func testViewModelIsInstantiatedWhenSettingRecoveryWords() {
    // initial assertions
    XCTAssertNil(self.sut.viewModel, "viewModel should initially be nil")

    // when
    self.sut.recoveryWords = TestHelpers.fakeWords()
    loadView()

    // then
    XCTAssertNotNil(self.sut.viewModel, "viewModel should eventually not be nil")
  }

  func testWhenSettingRecoveryWordsDDSIsInstantiated() {
    // initial assertions
    XCTAssertNil(self.sut.verificationCollectionViewDDS, "dds should initially be nil")

    // when
    self.sut.recoveryWords = TestHelpers.fakeWords()
    loadView()

    // then
    XCTAssertNotNil(self.sut.verificationCollectionViewDDS, "dds should initially be nil")
    XCTAssertFalse(self.sut.verificationCollectionView.dataSource === self.sut, "dataSource should not be the controller")
  }

  // MARK: VerifyRecoveryWordsResultDelegate tests
  func testDelegateAsksViewModelToCheckForAMatch() {
    self.sut.recoveryWords = TestHelpers.fakeWords()
    let cellData = self.sut.viewModel?.dataObjectsForVerification(withDelegate: self.sut).first
    let mockResultDelegate = MockVerifyRecoveryWordsResultDelegate()
    let mockViewModel = MockViewModel(words: TestHelpers.fakeWords(), resultDelegate: mockResultDelegate)
    self.sut.viewModel = mockViewModel

    loadView()
    self.sut.cell(VerifyRecoveryWordCell(), didSelectWord: "duder", withCellData: cellData!)

    XCTAssertTrue(mockViewModel.wasAskedToCheckMatch, "viewModel should be asked to check match")
  }

  func testFirstMatchFoundForwardsCollectionViewToNextCell() {
    // given
    self.sut.recoveryWords = TestHelpers.fakeWords()
    loadView()
    self.sut.verificationCollectionView.reloadData()
    self.sut.verificationCollectionView.layoutIfNeeded()
    let firstPath = self.sut.verificationCollectionView.indexPathsForVisibleItems.first

    // initial assertions
    XCTAssertEqual(firstPath?.item, 0, "first indexPath item should be 0")

    // when
    self.sut.firstMatchFound()
    self.sut.verificationCollectionView.layoutIfNeeded() // hack to redraw so visibleIndexPath is updated

    // then
    let newIndexPathItem = self.sut.verificationCollectionView.indexPathsForVisibleItems.first?.item
    XCTAssertEqual(newIndexPathItem, 1, "next indexPath item should be 1")
  }

  func testSecondMatchFoundTellsVerificationDelegateOfSuccess() {
    self.sut.recoveryWords = TestHelpers.fakeWords()
    loadView()

    self.sut.secondMatchFound()

    XCTAssertTrue(mockCoordinator.wordVerificationSucceededWasCalled, "delegate should be told verification succeeded")
  }

  func testErrorFoundTellsDelegate() {
    self.sut.recoveryWords = TestHelpers.fakeWords()
    loadView()

    self.sut.errorFound()

    XCTAssertTrue(mockCoordinator.wordVerificationFailedWasCalled, "delegate should be told of error")
  }

  func testFatalErrorFoundTellsDelegate() {
    self.sut.recoveryWords = TestHelpers.fakeWords()
    loadView()

    self.sut.fatalErrorFound()

    XCTAssertTrue(mockCoordinator.wordVerificationMaxFailuresAttemptedWasCalled, "max failures attempted should tell delegate")
  }

  // MARK: mock coordinator
  class MockCoordinator: VerifyRecoveryWordsViewControllerDelegate {

    var wordVerificationSucceededWasCalled = false
    func viewControllerDidSuccessfullyVerifyWords(_ viewController: UIViewController) {
      wordVerificationSucceededWasCalled = true
    }

    var viewControllerDidSkipBackupWasCalled = false
    func viewController(_ viewController: UIViewController, didSkipBackingUpWords words: [String]) {
      viewControllerDidSkipBackupWasCalled = true
    }

    var wordVerificationFailedWasCalled = false
    func viewControllerFailedWordVerification(_ viewController: UIViewController) {
      wordVerificationFailedWasCalled = true
    }

    var wordVerificationMaxFailuresAttemptedWasCalled = false
    func viewControllerWordVerificationMaxFailuresAttempted(_ viewController: UIViewController) {
      wordVerificationMaxFailuresAttemptedWasCalled = true
    }

    func viewController(_ viewController: UIViewController, shouldPromptToSkipWords words: [String]) {
    }
  }

  // MARK: mock view model
  class MockViewModel: VerifyRecoveryWordsViewModelType {
    required init(words: [String], resultDelegate: VerifyRecoveryWordsResultDelegate) {

    }

    func dataObjectsForVerification(withDelegate delegate: VerifyRecoveryWordSelectionDelegate) -> [VerifyRecoveryWordCellData] {
      return []
    }

    var wasAskedToCheckMatch = false
    func checkMatch(forWord word: String, cellData: VerifyRecoveryWordCellData) {
      wasAskedToCheckMatch = true
    }
  }
}
