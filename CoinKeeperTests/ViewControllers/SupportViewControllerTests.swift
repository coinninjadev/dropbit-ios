//
//  SupportViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 5/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class SupportViewControllerTests: XCTestCase {

  var sut: SupportViewController!
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    super.setUp()
    mockCoordinator = MockCoordinator()
    sut = SupportViewController.newInstance(with: mockCoordinator)
    _ = sut.view
  }

  override func tearDown() {
    mockCoordinator = nil
    sut = nil
    super.tearDown()
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.sendDebugInfoButton, "sendDebugInfoButton should be connected")
    XCTAssertNotNil(sut.tableView, "tableView should be connected")
    XCTAssertNotNil(sut.titleLabel, "titleLabel should be connected")
    XCTAssertNotNil(sut.closeButton, "closeButton should be connected")
  }

  // MARK: initial state
  func testCellText() {
    let count = SupportViewController.SupportType.allCases.count
    (0..<count).forEach { (index) in
      let path = IndexPath(row: index, section: 0)
      let cell = sut.tableView.dataSource?.tableView(sut.tableView, cellForRowAt: path) as? SettingCell
      let type = SupportViewController.SupportType.allCases[path.row]
      XCTAssertEqual(cell?.titleLabel.text, type.displayDescription)
    }
  }

  // MARK: buttons contain actions
  func testCloseButtonsContainsAction() {
    let actions = sut.closeButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(SupportViewController.close).description
    XCTAssertTrue(actions.contains(expected))
  }

  func testSendDebugInfoButtonContainsAction() {
    let actions = sut.sendDebugInfoButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let expected = #selector(SupportViewController.sendDebugInfo).description
    XCTAssertTrue(actions.contains(expected))
  }

  // MARK: actions produce results
  func testSendDebugInfoTellsDelegate() {
    sut.sendDebugInfoButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.wasAskedToSendDebugInfo)
  }

  func testCloseButtonTellsDelegate() {
    sut.closeButton.sendActions(for: .touchUpInside)
    XCTAssertTrue(mockCoordinator.wasAskedToClose)
  }

  func testTappingCellsOpensURLs() {
    let count = SupportViewController.SupportType.allCases.count
    (0..<count).forEach { (index) in
      let path = IndexPath(row: index, section: 0)
      sut.tableView.delegate?.tableView?(sut.tableView, didSelectRowAt: path)
      XCTAssertTrue(mockCoordinator.wasAskedToOpenURL)
      let expectedURL = SupportViewController.SupportType.allCases[index].url
      XCTAssertEqual(expectedURL, mockCoordinator.url)

      mockCoordinator.url = nil
      mockCoordinator.wasAskedToOpenURL = false
    }
  }

  // MARK: private
  class MockCoordinator: SupportViewControllerDelegate {
    var url: URL?
    var wasAskedToOpenURL = false
    func viewController(_ viewController: UIViewController, didRequestOpenURL url: URL) {
      wasAskedToOpenURL = true
      self.url = url
    }

    var wasAskedToSendDebugInfo = false
    func viewControllerSendDebuggingInfo(_ viewController: UIViewController) {
      wasAskedToSendDebugInfo = true
    }

    var wasAskedToClose = false
    func viewControllerDidSelectClose(_ viewController: UIViewController) {
      wasAskedToClose = true
    }
  }
}
