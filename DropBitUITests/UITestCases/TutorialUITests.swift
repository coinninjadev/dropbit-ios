//
//  TutorialUITests.swift
//  DropBitUITests
//
//  Created by Ben Winters on 10/15/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class TutorialUITests: UITestCase {

  override func setUp() {
    super.setUp()
    app.appendTestArguments([.resetPersistence, .skipTwitterAuthentication])
    app.launch()
  }

  func testFirstShowsTutorialViewController() {
    let recoveryWords = UITestHelpers.recoverOnlyWords()

    addSystemAlertMonitor()

    StartPage().tapRestore()
    PinCreationPage().enterSimplePin(digit: 1, times: 6)
    RestoreWalletPage().enterWords(recoveryWords)
    SuccessFailPage().checkWalletRecoverySucceeded().tapGoToWallet()
    DeviceVerificationPage().tapSkip()
    PushInfoPage()?.dismiss()
    TransactionHistoryPage().tapTutorialButton()

    let tutorialView = app.viewController(withId: .tutorial(.page))
    waitForElementToAppear(tutorialView)
    XCTAssert(tutorialView.exists, "Tutorial view not shown")

    let titleLabelOne = app.staticTexts["What is Bitcoin?"]
    XCTAssert(titleLabelOne.exists, "Title 1 does not exist")
    app.swipeLeft()

    let titleLabelTwo = app.staticTexts["Why the system is broken"]
    XCTAssert(titleLabelTwo.exists, "Title 2 does not exist")
    app.swipeLeft()

    let titleLabelThree = app.staticTexts["Recovery Words"]
    XCTAssert(titleLabelThree.exists, "Title 3 does not exist")
    app.swipeLeft()

    let titleLabelFour = app.staticTexts["Send Bitcoin via SMS"]
    XCTAssert(titleLabelFour.exists, "Title 4 does not exist")

    let mainButton = app.buttons["LET'S GO"]
    XCTAssert(mainButton.exists, "Main button not found")
  }

}
