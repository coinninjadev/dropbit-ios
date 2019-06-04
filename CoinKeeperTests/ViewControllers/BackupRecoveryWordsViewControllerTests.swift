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

  override func setUp() {
    super.setUp()
    self.sut = BackupRecoveryWordsViewController.makeFromStoryboard()
    _ = self.sut.view
  }

  override func tearDown() {
    self.sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(self.sut.titleLabel, "titleLabel should be connected")
    XCTAssertNotNil(self.sut.subtitleLabel, "subtitleLabel should be connected")
    XCTAssertNotNil(self.sut.wordCollectionView, "wordCollectionView should be connected")
    XCTAssertNotNil(self.sut.nextButton, "nextButton should be connected")
    XCTAssertNotNil(self.sut.backButton, "backButton should be connected")
  }

  // MARK: initial state
  func testBackgroundColorIsClear() {
    XCTAssertEqual(self.sut.view.backgroundColor, .lightGrayBackground)
  }

  func testCollectionViewInitialState() {
    self.sut.recoveryWords = TestHelpers.fakeWords()
    self.sut.viewDidLoad()

    XCTAssertNotNil(self.sut.wordCollectionView.delegate, "wordCollectionView delegate should not be nil")
    XCTAssertNotNil(self.sut.wordCollectionView.dataSource, "wordCollectionView dataSource should not be nil")
    XCTAssertFalse(self.sut.wordCollectionView.isUserInteractionEnabled, "isUserInteractionEnabled should be disabled")
    XCTAssertFalse(self.sut.wordCollectionView.showsHorizontalScrollIndicator, "showsHorizontalScrollIndicator should be disabled")
  }

  func testCollectionViewFlowLayoutInitialState() {
    self.sut.recoveryWords = TestHelpers.fakeWords()
    self.sut.viewDidLoad()
    let flowLayout = (self.sut.wordCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)
    let scrollDirection = flowLayout?.scrollDirection
    let itemsize = flowLayout?.itemSize
    let screenWidth = UIScreen.main.bounds.width

    XCTAssertEqual(scrollDirection, .horizontal)
    XCTAssertEqual(itemsize?.width, screenWidth)
  }

  func testNextButtonInitialState() {
    XCTAssertEqual(self.sut.nextButton.title(for: .normal), "NEXT")
  }

  func testBackButtonInitialState() {
    XCTAssertEqual(self.sut.backButton.title(for: .normal), "BACK")
    XCTAssertTrue(self.sut.backButton.isHidden, "backButton is initially hidden")
  }

  // MARK: outlets contain actions
  func testNextButtonContainsAction() {
    let actions = self.sut.nextButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let nextSelector = #selector(BackupRecoveryWordsViewController.nextButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(nextSelector), "nextButton should contain action")
  }

  func testBackButtonContainsAction() {
    let actions = self.sut.backButton.actions(forTarget: self.sut, forControlEvent: .touchUpInside) ?? []
    let backSelector = #selector(BackupRecoveryWordsViewController.backButtonTapped(_:)).description
    XCTAssertTrue(actions.contains(backSelector), "backButton should contain action")
  }

  // MARK: actions produce results
  func testCallingScrollToBeginningScrollsToFirstItem() {
    let initialItemPath = 5
    let expectedItemPath = 0
    setupWordsForNavigation()
    let path = IndexPath(item: initialItemPath, section: 0)
    self.sut.wordCollectionView.scrollToItem(at: path, at: .centeredHorizontally, animated: false)
    self.sut.wordCollectionView.layoutIfNeeded()  // hack - because reloadData() returns immediately

    // initial
    XCTAssertEqual(self.sut.wordCollectionView.indexPathsForVisibleItems.first?.item, initialItemPath)

    // when
    self.sut.reviewAllRecoveryWords()
    self.sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // then
    XCTAssertEqual(self.sut.wordCollectionView.indexPathsForVisibleItems.first?.item, expectedItemPath)
  }

  private func setupWordsForNavigation() {
    self.sut.recoveryWords = TestHelpers.fakeWords()
    self.sut.wordCollectionView.delegate = self.sut.wordCollectionViewDDS
    self.sut.wordCollectionView.dataSource = self.sut.wordCollectionViewDDS
    self.sut.wordCollectionView.reloadData()
    self.sut.wordCollectionView.layoutIfNeeded()  // hack - because reloadData() returns immediately
  }

  func testTappingNextButtonWhenOnFirstWordAdvancesToNextWord() {
    setupWordsForNavigation()

    // initial
    XCTAssertEqual(self.sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 0)
    XCTAssertTrue(self.sut.backButton.isHidden, "backButton should be initially hidden")

    // when
    self.sut.nextButton.sendActions(for: .touchUpInside)
    self.sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // then
    XCTAssertEqual(self.sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 1)
    XCTAssertFalse(self.sut.backButton.isHidden, "backButton should show after tapping Next")
  }

  func testTappingNextButtonWhenOnSecontToLastWordAdvancesToFinalWord() {
    setupWordsForNavigation()
    let eleventhIndexPath = IndexPath(item: 10, section: 0)
    self.sut.wordCollectionView.scrollToItem(at: eleventhIndexPath, at: .centeredHorizontally, animated: false)
    self.sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // initial
    XCTAssertEqual(self.sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 10)
    XCTAssertFalse(self.sut.backButton.isHidden, "backButton should be visible")
    XCTAssertEqual(self.sut.nextButton.title(for: .normal), "NEXT")
    XCTAssertEqual(self.sut.nextButton.backgroundColor, .primaryActionButton)

    // when
    self.sut.nextButton.sendActions(for: .touchUpInside)
    self.sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // then
    XCTAssertEqual(self.sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 11)
    XCTAssertFalse(self.sut.backButton.isHidden, "backButton should show after tapping Next")
    XCTAssertEqual(self.sut.nextButton.title(for: .normal), "VERIFY")
    XCTAssertEqual(self.sut.nextButton.backgroundColor, .darkBlueButton)
  }

  func testTappingNextButtonWhenOnLastWordTellsDelegateToVerifyWords() {
    setupWordsForNavigation()
    let mockCoordinator = MockCoordinator()
    self.sut.generalCoordinationDelegate = mockCoordinator
    let twelfthIndexPath = IndexPath(item: 11, section: 0)
    self.sut.wordCollectionView.scrollToItem(at: twelfthIndexPath, at: .centeredHorizontally, animated: false)
    self.sut.wordCollectionView.layoutIfNeeded() // hack - here too

    self.sut.nextButton.sendActions(for: .touchUpInside)

    XCTAssertTrue(mockCoordinator.wasAskedToVerifyWords, "coordinator should be told to verify words")
  }

  func testTappingBackButtonWhenOnLastWordScrollsAndChangesNextButton() {
    setupWordsForNavigation()
    let twelfthIndexPath = IndexPath(item: 11, section: 0)
    self.sut.wordCollectionView.scrollToItem(at: twelfthIndexPath, at: .centeredHorizontally, animated: false)
    self.sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // initially
    XCTAssertEqual(self.sut.nextButton.title(for: .normal), "VERIFY")
    XCTAssertEqual(self.sut.nextButton.backgroundColor, .darkBlueButton)
    XCTAssertEqual(self.sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 11)

    // when
    self.sut.backButton.sendActions(for: .touchUpInside)
    self.sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // then
    XCTAssertEqual(self.sut.nextButton.title(for: .normal), "NEXT")
    XCTAssertEqual(self.sut.nextButton.backgroundColor, .primaryActionButton)
    XCTAssertEqual(self.sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 10)
  }

  func testTappingBackButtonWhenOnNonFirstWordShowsPreviousWord() {
    setupWordsForNavigation()
    let fifthIndexPath = IndexPath(item: 4, section: 0)
    self.sut.wordCollectionView.scrollToItem(at: fifthIndexPath, at: .centeredHorizontally, animated: false)
    self.sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // initial
    XCTAssertEqual(self.sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 4)

    // when
    self.sut.backButton.sendActions(for: .touchUpInside)
    self.sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // then
    XCTAssertEqual(self.sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 3)
  }

  func testTappingBackButtonWhenOnSecondWordHidesBackButton() {
    setupWordsForNavigation()
    let secondIndexPath = IndexPath(item: 1, section: 0)
    self.sut.wordCollectionView.scrollToItem(at: secondIndexPath, at: .centeredHorizontally, animated: false)
    self.sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // initial
    XCTAssertEqual(self.sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 1)
    XCTAssertFalse(self.sut.backButton.isHidden)

    // when
    self.sut.backButton.sendActions(for: .touchUpInside)
    self.sut.wordCollectionView.layoutIfNeeded() // hack - here too

    // then
    XCTAssertEqual(self.sut.wordCollectionView.indexPathsForVisibleItems.first?.item, 0)
    XCTAssertTrue(self.sut.backButton.isHidden)
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
