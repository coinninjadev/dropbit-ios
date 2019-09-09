//
//  WalletAddressRequest.swift
//  DropBit
//
//  Created by BJ Miller on 7/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public struct WalletAddressRequest: Encodable {
  let status: String?
  let txid: String?
  let suppress: Bool?
}

extension WalletAddressRequest {
  static func sampleData() -> Data {
    return """
    {
      "status": "completed",
      "txid": "7f3a2790d59853fdc620b8cd23c8f68158f8bbdcd337a5f2451620d6f76d4e03"
    }
    """.data(using: .utf8)!
  }

  init(walletAddressRequestStatus: WalletAddressRequestStatus, txid: String? = nil) {
    self.status = walletAddressRequestStatus.rawValue
    self.txid = txid
    self.suppress = nil
  }

  init(suppress: Bool) {
    self.status = nil
    self.txid = nil
    self.suppress = suppress
  }

}
