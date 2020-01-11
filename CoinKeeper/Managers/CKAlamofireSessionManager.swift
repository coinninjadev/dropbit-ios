//
//  CKAlamofireSessionManager.swift
//  DropBit
//
//  Created by Ben Winters on 6/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Alamofire
import Foundation

/// This session manager is used by Moya to customize the request timeout intervals.
class CKAlamofireSessionManager: Alamofire.SessionManager {

  static let shared: CKAlamofireSessionManager = {
    let configuration = URLSessionConfiguration.default
    configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
    configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    configuration.urlCache = nil
    return CKAlamofireSessionManager(configuration: configuration)
  }()

}
