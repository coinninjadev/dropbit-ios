//
//  ServerAddressViewModel.swift
//  DropBit
//
//  Created by Mitch on 10/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class ServerAddressViewModel {
  var address: String
  var derivationString: String

  init?(serverAddress: CKMServerAddress) {
    guard let derivationPath = serverAddress.derivativePath?.fullPublicPath() else { return nil }
    address = serverAddress.address
    derivationString = derivationPath
  }
}
