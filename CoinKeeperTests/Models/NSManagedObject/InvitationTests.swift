//
//  InvitationTests.swift
//  DropBit
//
//  Created by Ben Winters on 9/26/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import CoreData
import CNBitcoinKit
import PhoneNumberKit
import XCTest

class InvitationTests: XCTestCase {

  var context: NSManagedObjectContext!

  let phoneNumberKit = PhoneNumberKit()

  override func setUp() {
    super.setUp()
    self.context = InMemoryCoreDataStack().context
  }

  override func tearDown() {
    self.context = nil
    super.tearDown()
  }

  func testAddressesProvidedForReceivedPendingDropBits() {

    let addressA = UUID().uuidString
    let addressB = UUID().uuidString
    let addressC = UUID().uuidString

    let expectedAddresses = [addressA, addressC].asSet()
    let excludedAddresses = [addressB].asSet()

    // Create invitations for both sets
    let responses = expectedAddresses.map { address in
      return WalletAddressRequestResponse(id: UUID().uuidString,
                                          createdAt: Date(),
                                          updatedAt: Date(),
                                          address: address,
                                          addressPubkey: nil,
                                          txid: nil,
                                          metadata: nil,
                                          identityHash: nil,
                                          status: WalletAddressRequestStatus.new.rawValue,
                                          deliveryId: nil,
                                          deliveryStatus: nil,
                                          walletId: nil)
    }

    let excludedResponses = excludedAddresses.map { address in
      return WalletAddressRequestResponse(id: UUID().uuidString,
                                          createdAt: Date(),
                                          updatedAt: Date(),
                                          address: address,
                                          addressPubkey: nil,
                                          txid: nil,
                                          metadata: nil,
                                          identityHash: nil,
                                          status: WalletAddressRequestStatus.expired.rawValue,
                                          deliveryId: nil,
                                          deliveryStatus: nil,
                                          walletId: nil)
    }

    (responses + excludedResponses).forEach { res in
      _ = CKMInvitation.updateOrCreate(withAddressRequestResponse: res,
                                       side: .received,
                                       kit: self.phoneNumberKit,
                                       in: context)
    }

    let fetchedAddresses = CKMInvitation.addressesProvidedForReceivedPendingDropBits(in: context).asSet()

    XCTAssertEqual(expectedAddresses.count, fetchedAddresses.count, "Fetched pending DropBit addresses should match the count of expected addresses")
    XCTAssertEqual(expectedAddresses, fetchedAddresses, "Fetched pending DropBit addresses should match the expected addresses")
    XCTAssertFalse(fetchedAddresses.contains(addressB), "Address B should be excluded from fetched addresses")
  }

}
