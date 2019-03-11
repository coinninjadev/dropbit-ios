//
//  NetworkManager+MessageRequestable.swift
//  DropBit
//
//  Created by Ben Winters on 10/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit

protocol MessageRequestable: AnyObject {
  func queryForMessages() -> Promise<[MessageResponse]>
}

extension NetworkManager: MessageRequestable {

  func queryForMessages() -> Promise<[MessageResponse]> {
    let body = buildElasticRequest()
    return cnProvider.requestList(MessagesTarget.query(body))
  }

  private func buildElasticRequest() -> ElasticRequest {
    let terms = ElasticTerms.object(withPlatforms: [.all, .ios])
    let script = ElasticScript(id: "semver", version: Global.version.value)
    let query = ElasticQuery(range: nil, script: script, term: nil, terms: terms)
    return ElasticRequest(query: query)
  }

}
