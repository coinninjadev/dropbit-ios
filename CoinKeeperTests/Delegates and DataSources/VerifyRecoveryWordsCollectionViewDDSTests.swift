//
//  VerifyRecoveryWordsCollectionViewDDSTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 3/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class VerifyRecoveryWordsCollectionViewDDSTests: XCTestCase {
  var sut: VerifyRecoveryWordsCollectionViewDDS!
  var fakeCollectionView: UICollectionView!
  var dataObjects: [VerifyRecoveryWordCellData] = []
  // swiftlint:disable:next weak_delegate
  var mockSelectionDelegate: MockVerifyRecoveryWordsSelectionDelegate!

  override func setUp() {
    super.setUp()
    let layout = UICollectionViewFlowLayout()
    let frame = CGRect(x: 0, y: 0, width: 200, height: 200)
    let mockResultDelegate = MockVerifyRecoveryWordsResultDelegate()
    let viewModel = VerifyRecoveryWordsViewModel(words: TestHelpers.fakeWords(), resultDelegate: mockResultDelegate)
    mockSelectionDelegate = MockVerifyRecoveryWordsSelectionDelegate()
    self.dataObjects = viewModel.dataObjectsForVerification(withDelegate: mockSelectionDelegate)
    self.fakeCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
    self.sut = VerifyRecoveryWordsCollectionViewDDS(dataObjects: self.dataObjects)
    self.fakeCollectionView.registerNib(cellType: VerifyRecoveryWordCell.self)
    self.fakeCollectionView.dataSource = self.sut
  }

  override func tearDown() {
    self.sut = nil
    self.fakeCollectionView = nil
    self.dataObjects = []
    mockSelectionDelegate = nil
    super.tearDown()
  }

  // MARK: dataSource methods
  func testNumberOfItemsInSectionValue() {
    let expectedNumber = 2
    let actualNumber = self.sut.collectionView(self.fakeCollectionView, numberOfItemsInSection: 0)
    XCTAssertEqual(actualNumber, expectedNumber, "there should be 2 items")
  }

  func testNumberOfSectionsValue() {
    let expectedNumber = 1
    let actualNumber = self.sut.numberOfSections(in: self.fakeCollectionView)
    XCTAssertEqual(actualNumber, expectedNumber, "there should be 1 section")
  }

  func testCellForItemReturnsAValidInstance() {
    let indexPath = IndexPath(item: 0, section: 0)
    let cell = self.sut.collectionView(self.fakeCollectionView, cellForItemAt: indexPath) as? VerifyRecoveryWordCell
    XCTAssertTrue(cell?.selectionDelegate === mockSelectionDelegate)
  }
}
