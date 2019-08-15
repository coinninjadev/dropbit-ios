//
//  Typealiases.swift
//  CoinKeeper
//
//  Created by BJ Miller on 5/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

public typealias JSONObject = [String: Any]
public typealias JSONObjects = [JSONObject]
public typealias CKCompletion = () -> Void
public typealias CKErrorCompletion = (Error?) -> Void
