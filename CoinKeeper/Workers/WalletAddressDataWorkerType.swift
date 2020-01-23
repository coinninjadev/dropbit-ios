//
//  WalletAddressDataWorkerType.swift
//  DropBit
//
//  Created by Ben Winters on 1/16/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import PromiseKit

protocol WalletAddressDataWorkerType: AnyObject {

  var targetWalletAddressCount: Int { get }

  ///This will fulfill Void early if not verified.
  func updateServerPoolAddresses(in context: NSManagedObjectContext) -> Promise<Void>

  ///This will retrieve and register addresses from the wallet manager based on the lastReceiveIndex and the provided `number` (quantity).
  ///This may be used independently of the updateServerAddresses function.
  func registerAndPersistServerAddresses(number: Int, in context: NSManagedObjectContext) -> Promise<Void>
  func fetchAndFulfillReceivedAddressRequests(in context: NSManagedObjectContext) -> Promise<Void>
  func updateReceivedAddressRequests(in context: NSManagedObjectContext) -> Promise<Void>
  func updateSentAddressRequests(in context: NSManagedObjectContext) -> Promise<Void>
  func cancelInvitation(withID invitationID: String, in context: NSManagedObjectContext) -> Promise<Void>

  /// Useful for debugging and setting a clean slate during initial registration
  func deleteAllAddressesOnServer() -> Promise<Void>
}

extension WalletAddressDataWorkerType {
  var targetWalletAddressCount: Int { return 5 }
}
