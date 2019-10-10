//
//  ConfirmPaymentViewControllerTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 12/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit
import CNBitcoinKit
import PromiseKit

class ConfirmPaymentViewControllerTests: XCTestCase {

  var sut: ConfirmPaymentViewController!
  var mockCoordinator: MockCoordinator!

  override func setUp() {
    mockCoordinator = MockCoordinator()
    let viewModel = MockConfirmLightningPaymentViewModel()
    sut = ConfirmPaymentViewController.newInstance(type: .payment, viewModel: viewModel,
                                                   feeModel: .lightning, delegate: mockCoordinator)
    _ = sut.view
  }

  override func tearDown() {
    mockCoordinator = nil
    sut = nil
  }

  // MARK: outlets
  func testOutletsAreConnected() {
    XCTAssertNotNil(sut.closeButton, "closeButton should be connected")
    XCTAssertNotNil(sut.confirmView, "confirmView should be connected")
    XCTAssertNotNil(sut.networkFeeLabel, "networkFeeLabel should be connected")
    XCTAssertNotNil(sut.networkFeeLabel, "networkFeeLabel should be connected")
    XCTAssertNotNil(sut.contactLabel, "contactLabel should be connected")
    XCTAssertNotNil(sut.primaryAddressLabel, "primaryAddressLabel should be connected")
    XCTAssertNotNil(sut.secondaryAddressLabel, "secondaryAddressLabel should be connected")
    XCTAssertNotNil(sut.primaryCurrencyLabel, "primaryCurrencyLabel should be connected")
    XCTAssertNotNil(sut.secondaryCurrencyLabel, "secondaryCurrencyLabel should be connected")
    XCTAssertNotNil(sut.memoContainerView, "memoContainerView should be connected")
    XCTAssertNotNil(sut.avatarBackgroundView, "avatarBackgroundView should be connected")
    XCTAssertNotNil(sut.avatarImageView, "avatarImageView should be connected")
  }

  // MARK: buttons contain actions
  func testCloseButtonContainsAction() {
    let closeActions = sut.closeButton.actions(forTarget: sut, forControlEvent: .touchUpInside) ?? []
    let closeSelector = #selector(ConfirmPaymentViewController.closeButtonWasTouched).description
    XCTAssertTrue(closeActions.contains(closeSelector), "closeButton should contain action")
  }

  class MockCoordinator: ConfirmPaymentViewControllerDelegate {
    func payAndPersistLightningRequest(withInputs inputs: LightningPaymentInputs,
                                       invitation: CKMInvitation?,
                                       to receiver: OutgoingDropBitReceiver?) -> Promise<LNTransactionResponse> {
      return Promise { _ in }
    }

    func viewControllerDidSelectCloseWithToggle(_ viewController: UIViewController) { }
    var alertManager: AlertManagerType = MockAlertManager(notificationManager:
      NotificationManager(permissionManager: PermissionManager(),
                          networkInteractor: NetworkManager(persistenceManager: PersistenceManager(),
                                                            analyticsManager: AnalyticsManager())))
    var analyticsManager: AnalyticsManagerType = MockAnalyticsManager()
    var persistenceManager: PersistenceManagerType = MockPersistenceManager()

    var navigationController: UINavigationController {
      return UINavigationController()
    }

    var didHandleSuccessfully = false
    func handleSuccessfulLightningPaymentVerification(with inputs: LightningPaymentInputs) {
      didHandleSuccessfully = true
    }

    var didConfirmLightning = false
    func viewControllerDidConfirmLightningPayment(
      _ viewController: UIViewController,
      inputs: LightningPaymentInputs,
      receiver: OutgoingDropBitReceiver?) {
      didConfirmLightning = true
    }

    func confirmPaymentViewControllerDidLoad(_ viewController: UIViewController) { }

    func viewControllerDidConfirmOnChainPayment(
      _ viewController: UIKit.UIViewController,
      transactionData: CNBitcoinKit.CNBTransactionData,
      rates: ExchangeRates,
      outgoingTransactionData: OutgoingTransactionData) { }

    func viewControllerDidConfirmInvite(
      _ viewController: UIViewController,
      outgoingInvitationDTO: OutgoingInvitationDTO,
      walletTxType: WalletTransactionType) { }

    func viewControllerRequestedShowFeeTooExpensiveAlert(_ viewController: UIViewController) { }

    var closeButtonTapped = false
    func viewControllerDidSelectClose(_ viewController: UIViewController) {
      closeButtonTapped = true
    }

    func viewControllerDidSelectClose(_ viewController: UIViewController, completion: CKCompletion? ) {
      closeButtonTapped = true
    }

  }
}
