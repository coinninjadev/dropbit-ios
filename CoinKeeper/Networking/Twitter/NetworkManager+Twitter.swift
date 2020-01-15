//
//  NetworkManager+Twitter.swift
//  DropBit
//
//  Created by BJ Miller on 5/7/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit
import OAuthSwift

extension TwitterUser: CustomDebugStringConvertible {
  var debugDescription: String {
    return """

           ***
           id: \(idStr)
           name: \(name)
           screenName: \(screenName)
           url: \(url ?? "not provided")
           ***
           """
  }
}

protocol TwitterRequestable: AnyObject {
  func authorizeTwitterUser() -> Promise<TwitterOAuthStorage>
  func findTwitterUsers(using term: String) -> Promise<[TwitterUser]>
  func defaultFollowingList() -> Promise<[TwitterUser]>
  func retrieveTwitterUser(with userId: String) -> Promise<TwitterUser>

  var twitterOAuthManager: OAuth1Swift { get }
  func resetTwitterOAuthManager()
}

extension TwitterOAuth {
  var callbackURL: String {
    return "dropbit://"
  }
}

extension NetworkManager: TwitterRequestable {

  func findTwitterUsers(using term: String) -> Promise<[TwitterUser]> {
    return performTwitterSearch(using: term)
      .then { self.usersWithImages(for: $0) }
  }

  func defaultFollowingList() -> Promise<[TwitterUser]> {
    return fetchDefaultFriends().then { self.usersWithImages(for: $0) }
  }

  // MARK: private
  private func performTwitterSearch(using term: String) -> Promise<[TwitterUser]> {
    return Promise { seal in
      twitterOAuthManager.client.get(TwitterEndpoints.search.urlString,
                                     parameters: ["q": term, "count": 5],
                                     headers: nil) { (result: Swift.Result<OAuthSwiftResponse, OAuthSwiftError>) in
                                      switch result {
                                      case .success(let response):
                                        do {
                                          let users = try TwitterUser.decoder.decode([TwitterUser].self, from: response.data)
                                          seal.fulfill(users)
                                        } catch {
                                          seal.reject(error)
                                        }
                                      case .failure(let error):
                                        let mappedError = self.mappedError(from: error)
                                        seal.reject(mappedError)
                                      }
      }
    }
  }

  struct TwitterFriends: Decodable {
    let users: [TwitterUser]
  }

  private func fetchDefaultFriends() -> Promise<[TwitterUser]> {
    return Promise { seal in
      twitterOAuthManager.client.get(
        TwitterEndpoints.friends.urlString,
        parameters: ["skip_status": true, "count": 20, "include_user_entities": false],
        headers: nil) { (result: Swift.Result<OAuthSwiftResponse, OAuthSwiftError>) in
          switch result {
          case .success(let response):
            do {
              let users = try TwitterUser.decoder.decode(TwitterFriends.self, from: response.data).users
              seal.fulfill(users)
            } catch {
              seal.reject(error)
            }
          case .failure(let error):
            let mappedError = self.mappedError(from: error)
            seal.reject(mappedError)
          }
      }
    }
  }

  private func mappedError(from error: OAuthSwiftError) -> Error {
    guard let underlying = error.underlyingError,
      let response = (underlying as NSError).userInfo["OAuthSwiftError.response"] as? HTTPURLResponse,
      let headers = response.allHeaderFields as? [String: String]
      else { return error }

    if response.statusCode == 429,
      let retryString = headers["x-rate-limit-reset"],
      let retryTimestamp = Double(retryString) {
      let retryDate = Date(timeIntervalSince1970: retryTimestamp)
      return TwitterAPIError.rateLimitExceeded(retryDate)
    } else {
      return error
    }
  }

  private func usersWithImages(for users: [TwitterUser]) -> Promise<[TwitterUser]> {
    let promises = users.map { self.userWithImage(for: $0) }
    return when(fulfilled: promises)
  }

  private func userWithImage(for user: TwitterUser) -> Promise<TwitterUser> {
    guard let url = user.profileImageURL else { return Promise.value(user) }
    return Promise { seal in
      DispatchQueue(label: "profile image").async {
        do {
          let data = try Data(contentsOf: url)
          var copyUser = user
          copyUser.profileImageData = data
          seal.fulfill(copyUser)
        } catch {
          seal.fulfill(user)
        }
      }
    }
  }

  func authorizeTwitterUser() -> Promise<TwitterOAuthStorage> {
    // reset the manager to get a clean token state, but keep handler if exists.
    let handler = twitterOAuthManager.authorizeURLHandler
    resetTwitterOAuthManager()
    twitterOAuthManager.authorizeURLHandler = handler

    return Promise { seal in
      twitterOAuthManager.authorize(
        withCallbackURL: twitterOAuth.callbackURL,
        headers: nil) { (result: Swift.Result<OAuthSwift.TokenSuccess, OAuthSwiftError>) in
          switch result {
          case .success(let tokenSuccess):
            guard let userId = tokenSuccess.parameters["user_id"] as? String,
              let screenName = tokenSuccess.parameters["screen_name"] as? String else {
                seal.reject(TwitterOAuthError.noUserFound)
                return
            }
            let credentials = TwitterOAuthStorage(
              twitterOAuthToken: tokenSuccess.credential.oauthToken,
              twitterOAuthTokenSecret: tokenSuccess.credential.oauthTokenSecret,
              twitterUserId: userId,
              twitterScreenName: screenName
            )
            seal.fulfill(credentials)
          case .failure(let error):
            log.error(error, message: "oauth failure")
            if error.errorCode == DBTError.OAuth.invalidOrExpiredToken.errorCode {
              self.resetTwitterOAuthManager()
              seal.reject(DBTError.OAuth.invalidOrExpiredToken)
            } else {
              seal.reject(error)
            }
          }
      }
    }
  }

  func retrieveTwitterUser(with userId: String) -> Promise<TwitterUser> {
    return Promise { seal in
      twitterOAuthManager.client.get(
      TwitterEndpoints.getUser.urlString,
      parameters: ["user_id": userId],
      headers: nil) { (result: Swift.Result<OAuthSwiftResponse, OAuthSwiftError>) in
        switch result {
        case .success(let response):
          do {
            let user = try TwitterUser.decoder.decode(TwitterUser.self, from: response.data)
            if let url = user.profileImageURL {
              DispatchQueue(label: "profile image").async {
                do {
                  let data = try Data(contentsOf: url)
                  var copyUser = user
                  copyUser.profileImageData = data
                  seal.fulfill(copyUser)
                } catch {
                  seal.reject(error)
                }
              }
            } else {
              seal.fulfill(user)
            }
          } catch {
            seal.reject(error)
          }
        case .failure(let error):
          seal.reject(error)
        }
      }
    }
  }
}
