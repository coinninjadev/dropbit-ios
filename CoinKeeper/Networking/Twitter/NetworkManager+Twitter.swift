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
}

extension TwitterOAuth {
  var callbackURL: String {
    return "dropbit://"
  }
}

extension NetworkManager: TwitterRequestable {
  func getCurrentTwitterUser() -> Promise<TwitterUser> {
    return authorize().then { self.retrieveCurrentUser(with: $0.twitterScreenName) }
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
          success: { (credential: OAuthSwiftCredential, response: OAuthSwiftResponse?, params: OAuthSwift.Parameters) in
            print("oauth token: \(credential.oauthToken)")
            print("oauth token secret: \(credential.oauthTokenSecret)")
            print("oauth refresh token: \(credential.oauthRefreshToken)")
            print("params: \(params)")
            print("user id: \(params["user_id"])")
            print("screen name: \(params["screen_name"])")
            // do request here
            print("foo")

            guard let userId = params["user_id"] as? String, let screenName = params["screen_name"] as? String
              else { seal.reject(TwitterOAuthError.noUserFound) }
            let credentials = TwitterOAuthStorage(
              twitterOAuthToken: credential.oauthToken,
              twitterOAuthTokenSecret: credential.oauthTokenSecret,
              twitterUserId: userId,
              twitterScreenName: screenName)
            _ = self.persistenceManager.keychainManager.store(oauthCredentials: credentials)

            seal.fulfill(credentials)
          }) { (error: OAuthSwiftError) in
            print("failed. error: \(error.localizedDescription)")
            seal.reject(error)
          }
      }
    }
  }

  private func retrieveCurrentUser(with username: String) -> Promise<TwitterUser> {
    return Promise { seal in
      twitterOAuthManager.client.get(
        TwitterEndpoints.getUser.urlString,
        parameters: ["screen_name": username],
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
