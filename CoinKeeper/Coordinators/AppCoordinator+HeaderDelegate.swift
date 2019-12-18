//
//  AppCoordinator+HeaderDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 9/11/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension AppCoordinator: HeaderDelegate {

  func createHeaders(for bodyData: Data?, signBodyIfAvailable: Bool) -> DefaultHeaders? {
    guard let wmgr = walletManager else { return nil }
    let timeStamp = CKDateFormatter.rfc3339.string(from: Date())
    let platform = "ios"
    let appVersion = VersionInfo().appVersion

    var dataToSign = timeStamp.data(using: .utf8)
    if let bodyData = bodyData, signBodyIfAvailable {
      dataToSign = bodyData
    }

    do {
      let sig = try dataToSign.flatMap { (data: Data) throws -> String in
        return try wmgr.signatureSigning(data: data)
      }

      let pubKeyString = try wmgr.hexEncodedPublicKey()

      let deviceId = self.persistenceManager.brokers.device.findOrCreateDeviceId()
      let udid = persistenceManager.keychainManager.findOrCreateUDID()
      let buildEnvironment = ApplicationBuildEnvironment.current()
      var headers = DefaultHeaders(timeStamp: timeStamp,
                                   devicePlatform: platform,
                                   appVersion: appVersion,
                                   signature: sig,
                                   walletId: nil,
                                   userId: nil,
                                   deviceId: deviceId,
                                   pubKeyString: pubKeyString,
                                   udid: udid,
                                   buildEnvironment: buildEnvironment)

      let context = persistenceManager.viewContext
      context.performAndWait {
        headers.walletId = self.persistenceManager.brokers.wallet.walletId(in: context)
        headers.userId = self.persistenceManager.brokers.user.userId(in: context)
      }

      return headers
    } catch {
      log.error(error, message: "Failed to create headers.")
      return nil
    }
  }

}
