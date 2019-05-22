//
//  BackupRecoveryWordsCollectionDDSTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 2/28/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
@testable import DropBit
import XCTest

class BackupRecoveryWordsCollectionDDSTests: XCTestCase {
  var sut: BackupRecoveryWordsCollectionDDS!
  var fakeCollectionView: UICollectionView!
  var words: [String] = []

  override func setUp() {
    super.setUp()
    let frame = CGRect(x: 0, y: 0, width: 200, height: 200)
    let layout = UICollectionViewFlowLayout()
    self.fakeCollectionView = UICollectionView(frame: frame, collectionViewLayout: layout)
    self.words = TestHelpers.fakeWords()
    self.sut = BackupRecoveryWordsCollectionDDS(words: self.words, cellDisplayedHandler: { _ in })
    self.fakeCollectionView.dataSource = self.sut
  }

  override func tearDown() {
    self.sut = nil
    self.fakeCollectionView = nil
    self.words = []
  }

  // MARK: delegate methods
  func testNumberOfItemsInSectionValue() {
    let expectedNumber = 12
    let actualNumber = self.sut.collectionView(self.fakeCollectionView, numberOfItemsInSection: 0)
    XCTAssertEqual(actualNumber, expectedNumber, "there should be 12 items")
  }

  func testNumberOfSectionsValue() {
    let expectedNumber = 1
    let actualNumber = self.sut.numberOfSections(in: self.fakeCollectionView)
    XCTAssertEqual(actualNumber, expectedNumber, "there should be 1 section")
  }
}
