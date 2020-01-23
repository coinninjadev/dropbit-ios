//
//  AddressRequestFulfillmentWorker.swift
//  DropBit
//
//  Created by Ben Winters on 9/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import Moya
import PromiseKit
import UIKit

/// Create new instances of this as needed, do not assign them to an instance variable.
class AddressRequestFulfillmentWorker {

  let networkManager: NetworkManagerType
  let walletManager: WalletManagerType
  let persistenceManager: PersistenceManagerType
  let analyticsManager: AnalyticsManagerType

  init(walletAddressDataWorker worker: WalletAddressDataWorker) {
    self.networkManager = worker.networkManager
    self.walletManager = worker.walletManager
    self.persistenceManager = worker.persistenceManager
    self.analyticsManager = worker.analyticsManager
  }

  /// Returns new responses for the now fulfilled address requests
  func mapAndFulfillAddressRequests(for unfulfilledResponses: [WalletAddressRequestResponse],
                                    in context: NSManagedObjectContext) -> Promise<Void> {

    let unfulfilledOnChainResponses = unfulfilledResponses.filter { $0.addressTypeCase == .btc }
    let unfulfilledLightningResponses = unfulfilledResponses.filter { $0.addressTypeCase == .lightning }

    return self.fulfillAndPersistOnChainAddressRequests(for: unfulfilledOnChainResponses, in: context)
      .then(in: context) { self.fulfillAndPersistLightningAddressRequests(for: unfulfilledLightningResponses, in: context) }
  }

  /// Returns updated responses with the newly supplied addresses, as well as the bodies to be sent to the server
  private func fulfillAndPersistOnChainAddressRequests(for unfulfilledResponses: [WalletAddressRequestResponse],
                                                       in context: NSManagedObjectContext) -> Promise<Void> {

    let dataSource = walletManager.createAddressDataSource()
    let nextMetaAddresses = dataSource.nextAvailableReceiveAddresses(number: unfulfilledResponses.count,
                                                                     forServerPool: false,
                                                                     indicesToSkip: [],
                                                                     in: context)
    let nextAddressesWithPubKeys: [MetaAddress] = nextMetaAddresses.compactMap { MetaAddress(cnbMetaAddress: $0) }
    guard unfulfilledResponses.count == nextAddressesWithPubKeys.count else {
      return Promise(error: DBTError.Persistence.missingValue(key: "CNBMetaAddress.uncompressedPublicKey"))
    }

    // Modify the WalletAddressRequestResponses with the addresses so that those responses can be used to
    // update persistence with the address. The server patch request returns a different response type, WalletAddressResponse.
    var addressRequestResponsesWithAddresses: [WalletAddressRequestResponse] = []
    var addWalletAddressBodies: [AddWalletAddressBody] = []

    for (i, response) in unfulfilledResponses.enumerated() {
      let metaAddress = nextAddressesWithPubKeys[i]

      let modifiedResponse = response.copy(withAddress: metaAddress.address)
      addressRequestResponsesWithAddresses.append(modifiedResponse)

      let body = AddWalletAddressBody(address: metaAddress.address, pubkey: metaAddress.addressPubKey,
                                      type: .btc, walletAddressRequestId: response.id)
      addWalletAddressBodies.append(body)
    }

    return self.fulfillOnChainAddressRequests(with: addWalletAddressBodies, in: context).asVoid()
      .get(in: context) { _ in self.persistenceManager.persistReceivedAddressRequests(addressRequestResponsesWithAddresses, in: context) }
  }

  private func fulfillAndPersistLightningAddressRequests(for unfulfilledResponses: [WalletAddressRequestResponse],
                                                         in context: NSManagedObjectContext) -> Promise<Void> {

    return walletManager.hexEncodedPublicKeyPromise()
      .then { (key: String) -> Promise<[Promise<WalletAddressRequestResponse>]> in
        let promises = unfulfilledResponses
          .map { response in self.fulfillLightningAddressRequest(forResponse: response, withPubKey: key, in: context)}
        return Promise.value(promises)
      }
      .then { (promises: [Promise<WalletAddressRequestResponse>]) -> Promise<Void> in
        return when(fulfilled: promises)
          .get(in: context) { self.persistenceManager.persistReceivedAddressRequests($0, in: context) }
          .asVoid()
      }
  }

  private func fulfillLightningAddressRequest(forResponse unfulfilledResponse: WalletAddressRequestResponse,
                                              withPubKey pubKey: String,
                                              in context: NSManagedObjectContext) -> Promise<WalletAddressRequestResponse> {
    let address = WalletAddressesTarget.autogenerateInvoicesAddressValue
    let addressBody = AddWalletAddressBody(address: address, pubkey: pubKey, type: .lightning, walletAddressRequestId: unfulfilledResponse.id)
    let modifiedResponse = unfulfilledResponse.copy(withAddress: address)
    return self.networkManager.addWalletAddress(body: addressBody)
      .then { _ in return Promise.value(modifiedResponse) }
  }

  /// Because this uses when(fulfilled:), all addWalletAddress calls must succeed for the next promise to execute
  private func fulfillOnChainAddressRequests(with bodies: [AddWalletAddressBody],
                                             in context: NSManagedObjectContext) -> Promise<[WalletAddressResponse]> {
    return when(fulfilled: bodies.map { body in
      self.networkManager.addWalletAddress(body: body)
        .get { _ in self.analyticsManager.track(event: .dropbitAddressProvided, with: nil) }
    })
  }

}
