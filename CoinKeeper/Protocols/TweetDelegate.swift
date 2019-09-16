//
//  TwitterTweetingDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol TweetDelegate: class {
  func openTwitterURL(withMessage message: String)
}
