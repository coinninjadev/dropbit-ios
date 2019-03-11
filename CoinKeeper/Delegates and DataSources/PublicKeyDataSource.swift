//
//  PublicKeyDataSource.swift
//  CoinKeeper
//
//  Created by Ben Winters on 5/10/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

protocol WalletPublicKeyDataSource: Any {

  var publicKey: String { get }

}
