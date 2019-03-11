//
//  URLOpener.swift
//  CoinKeeper
//
//  Created by Ben Winters on 5/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol URLOpener: AnyObject {
  func openURL(_ url: URL, completionHandler completion: (() -> Void)?)
}
