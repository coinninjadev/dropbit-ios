//
//  DropBitSnapshot.swift
//  DropBitSnapshot
//
//  Created by Ben Winters on 10/9/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import XCTest

class DropBitSnapshot: UITestCase {

  override func setUp() {
    super.setUp()
    app.appendTestArguments([.resetPersistence, .skipTwitterAuthentication, .skipGlobalMessageDisplay, .loadMockTransactionHistory])
    setupSnapshot(app)
    app.launch()
  }

  func testSnapshot() {
    StartPage().tapNewWallet()
    PinCreationPage().enterSimplePin(digit: 1, times: 6)
    DeviceVerificationPage().tapSkip()
    PushInfoPage()?.dismiss()

    WalletOverviewPage(ifExists: { snapshot("a_History") }).tapMenu()
    DrawerPage(ifExists: { snapshot("b1_Menu") }).tapGetBitcoin()
    GetBitcoinPage(ifExists: { snapshot("b2_Get_Bitcoin") }).tapBack()

    WalletOverviewPage().tapMenu()
    DrawerPage().tapEarn()
    EarnPage(ifExists: { snapshot("b3_Earn") }).tapClose()

    WalletOverviewPage().tapMenu()
    DrawerPage().tapSettings()
    SettingsPage(ifExists: { snapshot("b4_Settings") }).tapClose()

    WalletOverviewPage().tapMenu()
    DrawerPage().tapVerificationStatus()
    VerificationStatusPage(ifExists: { snapshot("b5_Verification_Status") }).tapClose()

    WalletOverviewPage().tapMenu()
    DrawerPage().tapSpend()
    SpendPage(ifExists: { snapshot("b6_Spend") }).tapBack()

    WalletOverviewPage().tapMenu()
    DrawerPage().tapSupport()
    SupportPage(ifExists: { snapshot("b7_Support") }).tapClose()

    WalletOverviewPage().tapReceive()
    RequestPayPage(ifExists: { snapshot("c1_Receive_OnChain") }).tapClose()

    WalletOverviewPage()
      .tapFirstSummaryCell()
      .swipeDetailCells(count: 24, forEach: { index in
        let filename = self.description(withPrefix: "OnChain_Tx_Detail", number: index)
        snapshot(filename)
      })

    WalletOverviewPage()
      .tapLightning()
      .tapReceive()
    RequestPayPage(ifExists: { snapshot("e1_Receive_Lightning") })
      .enterAmount("12.34")
      .createInvoice()
      .takeSnapshot("e2_Receive_Lightning_Invoice")
      .tapClose()

    WalletOverviewPage()
      .tapFirstSummaryCell()
      .swipeDetailCells(count: 4, forEach: { index in
        let filename = self.description(withPrefix: "Lightning_Tx_Detail", number: index)
        snapshot(filename)
      })
  }

  ///Useful for describing screenshots with fastlane snapshot.
  ///Pads the number with leading zeros for consistent 3-digit numbers to correctly sort exported image files.
  private func description(withPrefix prefix: String, number: Int) -> String {
    let formatter = prefixedNumberFormatter
    let numberDesc = formatter.string(from: NSNumber(value: number)) ?? ""
    return "\(prefix)_\(numberDesc)"
  }

  private lazy var prefixedNumberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.minimumIntegerDigits = 3
    formatter.paddingPosition = .beforePrefix
    formatter.paddingCharacter = "0"
    return formatter
  }()

}

extension UITestPage {
  func takeSnapshot(_ name: String) -> Self {
    snapshot(name)
    return self
  }
}
