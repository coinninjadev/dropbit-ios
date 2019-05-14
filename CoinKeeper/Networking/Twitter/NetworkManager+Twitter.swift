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
           location: \(location ?? "not provided")
           url: \(url ?? "not provided")
           followersCount: \(followersCount ?? 0)
           friendsCount: \(friendsCount ?? 0)
           ***
           """
  }
}

protocol TwitterRequestable: AnyObject {
  func getCurrentTwitterUser() -> Promise<TwitterUser>
  func authorizedTwitterCredentials() -> Promise<TwitterOAuthStorage>
  func findTwitterUsers(using term: String) -> Promise<[TwitterUser]>
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
      .then { (users: [TwitterUser]) -> Promise<[TwitterUser]> in
        let promises = users.map { self.userWithImage(for: $0) }
        return when(fulfilled: promises)
      }
  }

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

            self.persistenceManager.keychainManager.store(oauthCredentials: credentials)

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
