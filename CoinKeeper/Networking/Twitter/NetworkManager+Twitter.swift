//
//  NetworkManager+Twitter.swift
//  DropBit
//
//  Created by BJ Miller on 5/7/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import PromiseKit
import OAuthSwift
import os.log

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
  func retrieveCurrentUser(with userId: String) -> Promise<TwitterUser>

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
      twitterOAuthManager.client.get(
        TwitterEndpoints.search.urlString,
        parameters: ["q": term, "count": 5],
        headers: nil,
        success: { (response: OAuthSwiftResponse) in
          do {
            let users = try TwitterUser.decoder.decode([TwitterUser].self, from: response.data)
            seal.fulfill(users)
          } catch {
            seal.reject(error)
          }
      },
        failure: { (error: OAuthSwiftError) in
          seal.reject(error)
      })
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
        headers: nil,
        success: { (response: OAuthSwiftResponse) in
          do {
            let users = try TwitterUser.decoder.decode(TwitterFriends.self, from: response.data).users
            seal.fulfill(users)
          } catch {
            seal.reject(error)
          }
      },
        failure: { (error: OAuthSwiftError) in
          seal.reject(error)
      })
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
    return Promise { seal in
      twitterOAuthManager.authorize(
        withCallbackURL: twitterOAuth.callbackURL,
        success: { (credential: OAuthSwiftCredential, _: OAuthSwiftResponse?, params: OAuthSwift.Parameters) in
          guard let userId = params["user_id"] as? String, let screenName = params["screen_name"] as? String else {
            seal.reject(TwitterOAuthError.noUserFound)
            return
          }
          let credentials = TwitterOAuthStorage(
            twitterOAuthToken: credential.oauthToken,
            twitterOAuthTokenSecret: credential.oauthTokenSecret,
            twitterUserId: userId,
            twitterScreenName: screenName)

          seal.fulfill(credentials)
      },
        failure: { (error: OAuthSwiftError) in
          let logger = OSLog(subsystem: "com.coinninja.networkmanager", category: "twitter_oauth")
          os_log("oauth failure in %@. error: %@", log: logger, type: .error, #function, error.localizedDescription)
          // "Invalid or expired token"
          // "This feature is temporarily unavailable"
          if error.errorCode == CKOAuthError.invalidOrExpiredToken.errorCode || error.localizedDescription.contains("Invalid or expired token") {
            self.resetTwitterOAuthManager()
            seal.reject(CKOAuthError.invalidOrExpiredToken)
          } else {
            seal.reject(error)
          }
        }
      )
    }
  }

  func retrieveCurrentUser(with userId: String) -> Promise<TwitterUser> {
    return Promise { seal in
      twitterOAuthManager.client.get(
        TwitterEndpoints.getUser.urlString,
        parameters: ["user_id": userId],
        headers: nil,
        success: { (response: OAuthSwiftResponse) in
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
        },
        failure: { (error: OAuthSwiftError) in
          seal.reject(error)
        }
      )
    }
  }
}
