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
  func getCurrentTwitterUser() -> Promise<TwitterUser>
  func authorizedTwitterCredentials() -> Promise<TwitterOAuthStorage>
  func findTwitterUsers(using term: String) -> Promise<[TwitterUser]>
  func defaultFollowingList() -> Promise<[TwitterUser]>
  func selected(user: TwitterUser) -> Promise<Void>
}

extension TwitterOAuth {
  var callbackURL: String {
    return "dropbit://"
  }
}

extension NetworkManager: TwitterRequestable {
  func getCurrentTwitterUser() -> Promise<TwitterUser> {
    return authorize().then { self.retrieveCurrentUser(with: $0.twitterUserId) }
  }

  func authorizedTwitterCredentials() -> Promise<TwitterOAuthStorage> {
    return authorize()
  }

  func findTwitterUsers(using term: String) -> Promise<[TwitterUser]> {
    return authorize()
      .then { _ in self.performTwitterSearch(using: term) }
      .then { self.usersWithImages(for: $0) }
  }

  func defaultFollowingList() -> Promise<[TwitterUser]> {
    return authorize()
      .then { _ in self.fetchDefaultFriends() }
      .then { self.usersWithImages(for: $0) }
  }

  func selected(user: TwitterUser) -> Promise<Void> {
    return Promise { _ in }
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

  private func authorize() -> Promise<TwitterOAuthStorage> {
    return Promise { seal in
      if let credentials = persistenceManager.keychainManager.oauthCredentials() {
        let newCredential = OAuthSwiftCredential(consumerKey: twitterOAuth.consumerKey, consumerSecret: twitterOAuth.consumerSecret)
        newCredential.oauthToken = credentials.twitterOAuthToken
        newCredential.oauthTokenSecret = credentials.twitterOAuthTokenSecret
        twitterOAuthManager.client = OAuthSwiftClient(credential: newCredential)
        seal.fulfill(credentials)
      } else {
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
            print("failed. error: \(error.localizedDescription)")
            seal.reject(error)
          }
        )
      }
    }
  }

  private func retrieveCurrentUser(with userId: String) -> Promise<TwitterUser> {
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
