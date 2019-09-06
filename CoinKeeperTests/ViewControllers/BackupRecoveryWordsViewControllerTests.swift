//
//  BackupRecoveryWordsViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class BackupRecoveryWordsViewControllerTests: XCTestCase {
  var sut: BackupRecoveryWordsViewController!
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    super.setUp()
    mockCoordinator = MockCoordinator()
    sut = BackupRecoveryWordsViewController.newInstance(withDelegate: mockCoordinator, recoveryWords: TestHelpers.fakeWords(), wordsBackedUp: false)
    _ = sut.view
  }

  override func tearDown() {
    mockCoordinator = nil
    sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.titleLabel, "titleLabel should be connected")
    XCTAssertNotNil(sut.subtitleLabel, "subtitleLabel should be connected")
    XCTAssertNotNil(sut.wordCollectionView, "wordCollectionView should be connected")
    XCTAssertNotNil(sut.nextButton, "nextButton should be connected")
    XCTAssertNotNil(sut.backButton, "backButton should be connected")
  }

  // MARK: initial state
  func testBackgroundColorIsClear() {
    XCTAssertEqual(sut.view.backgroundColor, .lightGrayBackground)
  }

  func testCollectionViewInitialState() {
    XCTAssertNotNil(sut.wordCollectionView.delegate, "wordCollectionView delegate should not be nil")
    XCTAssertNotNil(sut.wordCollectionView.dataSource, "wordCollectionView dataSource should not be nil")
    XCTAssertFalse(sut.wordCollectionView.isUserInteractionEnabled, "isUserInteractionEnabled should be disabled")
    XCTAssertFalse(sut.wordCollectionView.showsHorizontalScrollIndicator, "showsHorizontalScrollIndicator should be disabled")
  }

  func testCollectionViewFlowLayoutInitialState() {
    let flowLayout = (sut.wordCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)
    let scrollDirection = flowLayout?.scrollDirection
    let itemsize = flowLayout?.itemSize
    let screenWidth = UIScreen.main.bounds.width

    XCTAssertEqual(scrollDirection, .horizontal)
    XCTAssertEqual(itemsize?.width, screenWidth)
  }

  func testNextButtonInitialState() {
    XCTAssertEqual(sut.nextButton.title(for: .normal), "NEXT")
  }

  func testBackButtonInitialState() {
    XCTAssertEqual(sut.backButton.title(for: .normal), "BACK")
    XCTAssertTrue(sut.backButton.isHidden, "backButton is initially hidden")
  }

  // MARK: outlets contain actions
  func testNextButtonContainsAction() {
    let actions = sut.nextButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let nextSelector = #selector(BackupRecoveryWordsViewController.nextButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(nextSelector), "nextButton should contain action")
  }

  func testBackButtonContainsAction() {
    let actions = sut.backButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let backSelector = #selector(BackupRecoveryWordsViewController.backButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(backSelector), "backButton should contain action")
  }

  // MARK: actions produce results
  func testCallingScrollToBeginningScrollsToFirstItem() {
    let initialItemPath = 5
    let expectedItemPath = 0
    setupWordsForNavigation()
    let path = IndexPath(item: initialItemPath, section: 0)
    sut.wordCollectionView.scrollToItem(at: path, at: .centeredHorizontally, animated: false)
    sut.wordCollectionView.layoutIfNeeded()  // hack - because reloadData() returns immediately

    // initial
    XCTAssertEqual(sut.wordCollectionView.indexPathsForVisibleItems.first?.item, initialItemPath)

    // when
    sut.reviewAllRecoveryWords()
    sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // then
    XCTAssertEqual(sut.wordCollectionView.indexPathsForVisibleItems.first?.item, expectedItemPath)
  }

  private func setupWordsForNavigation() {
    sut.wordCollectionView.delegate = sut.wordCollectionViewDDS
    sut.wordCollectionView.dataSource = sut.wordCollectionViewDDS
    sut.wordCollectionView.reloadData()
    sut.wordCollectionView.layoutIfNeeded()  // hack - because reloadData() returns immediately
  }

  func testTappingNextButtonWhenOnFirstWordAdvancesToNextWord() {
    setupWordsForNavigation()

    // initial
    XCTAssertEqual(sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 0)
    XCTAssertTrue(sut.backButton.isHidden, "backButton should be initially hidden")

    // when
    sut.nextButton.sendActions(for: .touchUpInside)
    sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // then
    XCTAssertEqual(sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 1)
    XCTAssertFalse(sut.backButton.isHidden, "backButton should show after tapping Next")
  }

  func testTappingNextButtonWhenOnSecontToLastWordAdvancesToFinalWord() {
    setupWordsForNavigation()
    let eleventhIndexPath = IndexPath(item: 10, section: 0)
    sut.wordCollectionView.scrollToItem(at: eleventhIndexPath, at: .centeredHorizontally, animated: false)
    sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // initial
    XCTAssertEqual(sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 10)
    XCTAssertFalse(sut.backButton.isHidden, "backButton should be visible")
    XCTAssertEqual(sut.nextButton.title(for: .normal), "NEXT")
    XCTAssertEqual(sut.nextButton.backgroundColor, .primaryActionButton)

    // when
    sut.nextButton.sendActions(for: .touchUpInside)
    sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // then
    XCTAssertEqual(sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 11)
    XCTAssertFalse(sut.backButton.isHidden, "backButton should show after tapping Next")
    XCTAssertEqual(sut.nextButton.title(for: .normal), "VERIFY")
    XCTAssertEqual(sut.nextButton.backgroundColor, .darkBlueBackground)
  }

  func testTappingNextButtonWhenOnLastWordTellsDelegateToVerifyWords() {
    setupWordsForNavigation()
    let mockCoordinator = MockCoordinator()
    sut.delegate = mockCoordinator
    let twelfthIndexPath = IndexPath(item: 11, section: 0)
    sut.wordCollectionView.scrollToItem(at: twelfthIndexPath, at: .centeredHorizontally, animated: false)
    sut.wordCollectionView.layoutIfNeeded() // hack - here too

    sut.nextButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.wasAskedToVerifyWords, "coordinator should be told to verify words")
  }

  func testTappingBackButtonWhenOnLastWordScrollsAndChangesNextButton() {
    setupWordsForNavigation()
    let twelfthIndexPath = IndexPath(item: 11, section: 0)
    sut.wordCollectionView.scrollToItem(at: twelfthIndexPath, at: .centeredHorizontally, animated: false)
    sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // initially
    XCTAssertEqual(sut.nextButton.title(for: .normal), "VERIFY")
    XCTAssertEqual(sut.nextButton.backgroundColor, .darkBlueBackground)
    XCTAssertEqual(sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 11)

    // when
    sut.backButton.sendActions(for: .touchUpInside)
    sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // then
    XCTAssertEqual(sut.nextButton.title(for: .normal), "NEXT")
    XCTAssertEqual(sut.nextButton.backgroundColor, .primaryActionButton)
    XCTAssertEqual(sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 10)
  }

  func testTappingBackButtonWhenOnNonFirstWordShowsPreviousWord() {
    setupWordsForNavigation()
    let fifthIndexPath = IndexPath(item: 4, section: 0)
    sut.wordCollectionView.scrollToItem(at: fifthIndexPath, at: .centeredHorizontally, animated: false)
    sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // initial
    XCTAssertEqual(sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 4)

    // when
    sut.backButton.sendActions(for: .touchUpInside)
    sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // then
    XCTAssertEqual(sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 3)
  }

  func testTappingBackButtonWhenOnSecondWordHidesBackButton() {
    setupWordsForNavigation()
    let secondIndexPath = IndexPath(item: 1, section: 0)
    sut.wordCollectionView.scrollToItem(at: secondIndexPath, at: .centeredHorizontally, animated: false)
    sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // initial
    XCTAssertEqual(sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 1)
    XCTAssertFalse(sut.backButton.isHidden)

    // when
    sut.backButton.sendActions(for: .touchUpInside)
    sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // then
    XCTAssertEqual(sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 0)
    XCTAssertTrue(sut.backButton.isHidden)
  }

  class MockCoordinator: BackupRecoveryWordsViewControllerDelegate {

    var wasAskedToVerifyWords = false
    var words: [String] = []
    func viewController(_ viewController: UIViewController, didFinishWords words: [String]) {
      wasAskedToVerifyWords = true
      self.words = words
    }
    func viewController(_ viewController: UIViewController, shouldPromptToSkipWords words: [String]) {}
  }
}
