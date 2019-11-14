//
//  TransactionNotificationsElasticQuery.swift
//  DropBit
//
//  Created by Ben Winters on 11/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class TransactionNotificationsElasticQuery: ElasticQuery {

  init(ids: [String]) {
    let terms = ElasticTerms.object(withTxids: ids)
    super.init(range: nil, script: nil, term: nil, terms: terms)
  }

}
