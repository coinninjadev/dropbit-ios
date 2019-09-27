//
//  WalletAddressDataWorkerTests.swift
//  DropBitTests
//
//  Created by Ben Winters on 7/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import XCTest
import Moya
import PromiseKit
import CoreData
@testable import DropBit

class WalletAddressDataWorkerTests: MockedPersistenceTestCase {
  var sut: WalletAddressDataWorker!

  var mockNetworkManager: MockNetworkManager!
  var mockWalletManager: MockWalletManager!
  var mockAnalyticsManager: MockAnalyticsManager!
  var mockAppCoordinator: MockAppCoordinator!

  // swiftlint:disable weak_delegate
  var mockWalletDelegate: MockWalletDelegate!
  var mockInvitationDelegate: MockInvitationDelegate!

  override func setUp() {
    super.setUp()

    mockBrokers.mockUser.userIdValue = "34gvbew4gv-qw3yrq3fjh-w3qruihwefs-3fsw34g"
    mockNetworkManager = MockNetworkManager(persistenceManager: mockPersistenceManager, analyticsManager: MockAnalyticsManager())
    mockWalletManager = MockWalletManager(words: [])
    mockInvitationDelegate = MockInvitationDelegate()
    mockAnalyticsManager = MockAnalyticsManager()
    mockAppCoordinator = MockAppCoordinator()

    sut = WalletAddressDataWorker(walletManager: mockWalletManager,
                                  persistenceManager: mockPersistenceManager,
                                  networkManager: mockNetworkManager,
                                  analyticsManager: mockAnalyticsManager,
                                  paymentSendingDelegate: mockAppCoordinator,
                                  invitationWorkerDelegate: mockInvitationDelegate
    )
  }

  override func tearDown() {
    sut = nil
    mockWalletManager = nil
    mockNetworkManager = nil
    mockPersistenceManager = nil
    super.tearDown()
  }

  func testUnacknowledgedInvitationDeletion() {
    let expectation = XCTestExpectation(description: "unacknowledged invitation gets deleted")
    let stack = InMemoryCoreDataStack()
    mockNetworkManager.getWalletAddressRequestsResponse =
      try? WalletAddressRequestResponse.decoder.decode(WalletAddressRequestResponse.self, from: WalletAddressRequestResponse.sampleData)

    let globalNumber = GlobalPhoneNumber(countryCode: 1, nationalNumber: "330-555-4969")
    generateUnacknowledgedInvitation(with: GenericContact(phoneNumber: globalNumber, formatted: ""), in: stack.context)

    let invitation = CKMInvitation.findUnacknowledgedInvitations(in: stack.context)[0]
    mockBrokers.mockInvitation.unacknowledgedInvitations = [invitation]

    sut.handleUnacknowledgedSentInvitations(in: stack.context).done {
      XCTAssertTrue(!stack.context.insertedObjects.contains(invitation), "unacknowledged invitation should be deleted")
      expectation.fulfill()
      }.cauterize()

    wait(for: [expectation], timeout: 3.0)
  }

  func testUnacknowledgedInvitationDeletionWithoutDeletingOtherInvitations() {
    let expectation = XCTestExpectation(description: "unacknowledged invitation gets deleted")
    let stack = InMemoryCoreDataStack()
    mockNetworkManager.getWalletAddressRequestsResponse =
      try? WalletAddressRequestResponse.decoder.decode(WalletAddressRequestResponse.self, from: WalletAddressRequestResponse.sampleData)

    let globalNumber = GlobalPhoneNumber(countryCode: 1, nationalNumber: "330-555-4969")
    generateUnacknowledgedInvitation(with: GenericContact(phoneNumber: globalNumber, formatted: ""), in: stack.context)

    let otherInvitation = CKMInvitation(insertInto: stack.context)

    let unacknowledgedInvitation = CKMInvitation.findUnacknowledgedInvitations(in: stack.context)[0]
    mockBrokers.mockInvitation.unacknowledgedInvitations = [unacknowledgedInvitation]

    sut.handleUnacknowledgedSentInvitations(in: stack.context).done {
      XCTAssertTrue(!stack.context.insertedObjects.contains(unacknowledgedInvitation), "unacknowledged invitation should be deleted")
      XCTAssertTrue(stack.context.insertedObjects.contains(otherInvitation), "other invitation should not be deleted")
      expectation.fulfill()
      }.cauterize()

    wait(for: [expectation], timeout: 3.0)
  }

  private func generateUnacknowledgedInvitation(with contact: ContactType, in context: NSManagedObjectContext) {
    let acknowledgementId = UUID().uuidString
    let pair: BitcoinUSDPair = (btcAmount: 1, usdAmount: 7000)
    let outgoingInvitationDTO = OutgoingInvitationDTO(contact: contact, btcPair: pair, fee: 19,
                                                      walletTxType: .onChain, sharedPayloadDTO: nil)

    PersistenceManager().brokers.invitation.persistUnacknowledgedInvitation(
      withDTO: outgoingInvitationDTO,
      acknowledgmentId: acknowledgementId,
      in: context)
  }

  func testLinkFulfilledAddressRequestsWithTransaction() {
    let stack = InMemoryCoreDataStack()

    // Seed the context with an invitation, placeholder tx, and actual tx

    let broadcastTxid = "f231aaf68aff1e0957d3c9eb668772d6bb249f07a3176cc3c9c99dbe5e960f83"

    let placeholderTx = CKMTransaction(insertInto: stack.context)
    placeholderTx.txid = UUID().uuidString

    let sampleResponse = WalletAddressRequestResponse(id: UUID().uuidString,
                                                      createdAt: Date(),
                                                      updatedAt: Date(),
                                                      address: UUID().uuidString,
                                                      addressPubkey: nil,
                                                      addressType: nil,
                                                      txid: broadcastTxid,
                                                      metadata: nil,
                                                      identityHash: nil,
                                                      status: WalletAddressRequestStatus.completed.rawValue,
                                                      deliveryId: nil,
                                                      deliveryStatus: nil,
                                                      walletId: nil)

    let invitation = CKMInvitation(withAddressRequestResponse: sampleResponse,
                                   side: .received,
                                   insertInto: stack.context)
    placeholderTx.invitation = invitation

    let actualTx = CKMTransaction(insertInto: stack.context)
    actualTx.txid = broadcastTxid

    self.sut.linkFulfilledAddressRequestsWithTransaction(in: stack.context)

    XCTAssertTrue(placeholderTx.isDeleted, "placeholderTx should be deleted")
    XCTAssertTrue(actualTx.invitation == invitation, "the invitation should be linked to the actual transaction")
  }

  func testLinkFulfilledAddressRequestsWithTransaction_lightningInvoice() {
    let stack = InMemoryCoreDataStack(), placeholderWalletEntry = CKMWalletEntry(insertInto: stack.context)
    let invoice = "ln45gwu435nbsiurbsieu5ngkjsdfhgskjerhggi3u4hgrgergsthsrths46"

    let sampleResponse = WalletAddressRequestResponse(id: UUID().uuidString,
                                                      createdAt: Date(),
                                                      updatedAt: Date(),
                                                      address: UUID().uuidString,
                                                      addressPubkey: nil,
                                                      addressType: "lightning",
                                                      txid: invoice,
                                                      metadata: nil,
                                                      identityHash: nil,
                                                      status: WalletAddressRequestStatus.completed.rawValue,
                                                      deliveryId: nil,
                                                      deliveryStatus: nil,
                                                      walletId: nil)

    let invitation = CKMInvitation(withAddressRequestResponse: sampleResponse,
                                   side: .received,
                                   insertInto: stack.context)
    placeholderWalletEntry.invitation = invitation

    let targetWalletEntry = CKMWalletEntry(insertInto: stack.context)
    let ledgerEntry = CKMLNLedgerEntry(insertInto: stack.context)
    ledgerEntry.id = invoice
    targetWalletEntry.ledgerEntry = ledgerEntry

    self.sut.linkFulfilledAddressRequestsWithTransaction(in: stack.context)

    XCTAssertTrue(placeholderWalletEntry.isDeleted, "placeholder wallet entry should be deleted")
    XCTAssertTrue(targetWalletEntry.invitation == invitation, "the invitation should be linked to the actual transaction")
  }

  func testLinkFulfilledAddressRequestsWithTransaction_IgnoresUnmatchedInvitations() {
    let stack = InMemoryCoreDataStack()

    // Seed the context with an invitation, placeholder tx, and actual tx

    let broadcastTxid = "f231aaf68aff1e0957d3c9eb668772d6bb249f07a3176cc3c9c99dbe5e960f83"

    let placeholderTx = CKMTransaction(insertInto: stack.context)
    placeholderTx.txid = UUID().uuidString

    let sampleResponse = WalletAddressRequestResponse(id: UUID().uuidString,
                                                      createdAt: Date(),
                                                      updatedAt: Date(),
                                                      address: UUID().uuidString,
                                                      addressPubkey: nil,
                                                      addressType: nil,
                                                      txid: nil,
                                                      metadata: nil,
                                                      identityHash: nil,
                                                      status: WalletAddressRequestStatus.new.rawValue,
                                                      deliveryId: nil,
                                                      deliveryStatus: nil,
                                                      walletId: nil)

    let invitation = CKMInvitation(withAddressRequestResponse: sampleResponse,
                                   side: .received,
                                   insertInto: stack.context)
    placeholderTx.invitation = invitation

    let actualTx = CKMTransaction(insertInto: stack.context)
    actualTx.txid = broadcastTxid

    self.sut.linkFulfilledAddressRequestsWithTransaction(in: stack.context)

    XCTAssertFalse(placeholderTx.isDeleted, "placeholderTx should not be deleted")
    XCTAssertNil(actualTx.invitation, "the actual transaction should not have a linked invitation")
    XCTAssertTrue(placeholderTx.invitation == invitation, "the invitation should be linked to the placeholder transaction")
  }

  func testCheckAddressIntegrity_FiltersOutBadResponses() {
    let stack = InMemoryCoreDataStack()

    let expectation = XCTestExpectation(description: "valid responses")
    let validAddresses: [String] = [
      "1LjhdZ8bXywBsDxo22gAHf8VXJX9SUicNC",
      "37KDsaBB1iswyTmbvf5Pv573o67No8q5zU",
      "19msU2YhVj8kbszjyV3gPx9PuY3DJczCDC"
    ]
    let invalidAddresses: [String] = [
      "1NriCBq5f8jh1HXg3rkZGaLgWtLvftWbob",
      "1ASY35sNMds13xoAnzmSkiG4TeLdWL4nSc"
    ]
    let pubKey = "abc123"
    let validResponses = validAddresses.map { WalletAddressResponse(address: $0, addressPubkey: pubKey) }
    let invalidResponses = invalidAddresses.map { WalletAddressResponse(address: $0, addressPubkey: pubKey) }
    let allResponses = validResponses + invalidResponses

    let mockAddressSource = MockAddressDataSource()
    mockAddressSource.validAddresses = validAddresses
    self.sut.checkAddressIntegrity(of: allResponses, addressDataSource: mockAddressSource, in: stack.context)
      .done { resultResponses in
        let resultAddresses = resultResponses.compactMap { $0.address }
        XCTAssertTrue(resultAddresses == validAddresses, "The result should match the valid addresses")
        XCTAssertTrue(resultResponses.count == validResponses.count, "The result response count should match the valid response count")
        XCTAssertTrue(resultResponses.count <= allResponses.count, "The result response count should be less than or equal to allResponses")
        for iAddress in invalidAddresses {
          XCTAssertFalse(resultAddresses.contains(iAddress), "The result addresses should not contain any invalid addresses")
        }
        expectation.fulfill()
      }.cauterize()

    wait(for: [expectation], timeout: 10.0)
  }

  func testCheckAddressIntegrity_SendsFlare() {
    let stack = InMemoryCoreDataStack()

    let expectation = XCTestExpectation(description: "valid responses")
    let validAddresses: [String] = [
      "1LjhdZ8bXywBsDxo22gAHf8VXJX9SUicNC",
      "37KDsaBB1iswyTmbvf5Pv573o67No8q5zU",
      "19msU2YhVj8kbszjyV3gPx9PuY3DJczCDC"
    ]
    let invalidAddresses: [String] = [
      "1NriCBq5f8jh1HXg3rkZGaLgWtLvftWbob",
      "1ASY35sNMds13xoAnzmSkiG4TeLdWL4nSc"
    ]
    let pubKey = "abc123"
    let validResponses = validAddresses.map { WalletAddressResponse(address: $0, addressPubkey: pubKey) }
    let invalidResponses = invalidAddresses.map { WalletAddressResponse(address: $0, addressPubkey: pubKey) }
    let allResponses = validResponses + invalidResponses

    let mockAddressSource = MockAddressDataSource()
    mockAddressSource.validAddresses = validAddresses
    self.sut.checkAddressIntegrity(of: allResponses, addressDataSource: mockAddressSource, in: stack.context)
      .done { _ in
        XCTAssertNotNil(self.mockAnalyticsManager.eventValueString, "Address integrity eventValueString should be non-nil")
        expectation.fulfill()
      }.cauterize()

    wait(for: [expectation], timeout: 10.0)
  }

}

class MockInvitationDelegate: InvitationWorkerDelegate {
  func fetchSatisfiedSentWalletAddressRequests() -> Promise<[WalletAddressRequestResponse]> {
    return Promise { _ in }
  }
  func didBroadcastTransaction() { }
}
