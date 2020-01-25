//
//  CKRequestHeadersProvider.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 1/20/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/**
 The headers provided in this dictionary should not include the signature
 or timestamp as those are added automatically through the AuthPlugin.
 */
public protocol CKRequestHeadersProvider {
  var dictionary: Headers { get }
}
