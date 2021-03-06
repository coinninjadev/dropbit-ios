//
//  CKMTwitterContact+CoreDataClass.swift
//  DropBit
//
//  Created by BJ Miller on 5/16/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CKMTwitterContact)
public class CKMTwitterContact: NSManagedObject, TwitterUserFormattable {

  var twitterScreenName: String {
    return displayScreenName
  }

  static func findOrCreate(with contact: TwitterContactType, in context: NSManagedObjectContext) -> CKMTwitterContact {
    let fetchRequest: NSFetchRequest<CKMTwitterContact> = CKMTwitterContact.fetchRequest()
    let idKeyPath = #keyPath(CKMTwitterContact.identityHash)
    let predicate = NSPredicate(format: "\(idKeyPath) = %@", contact.identityHash)
    fetchRequest.predicate = predicate
    fetchRequest.fetchLimit = 1

    var twitterContact: CKMTwitterContact!
    do {
      if let foundContact = try context.fetch(fetchRequest).first {
        twitterContact = foundContact
      } else {
        twitterContact = CKMTwitterContact(insertInto: context)
      }
    } catch {
      twitterContact = CKMTwitterContact(insertInto: context)
    }

    twitterContact.configure(with: contact, in: context)

    return twitterContact
  }

  static func findAllNeedingInflated(in context: NSManagedObjectContext) -> [CKMTwitterContact] {
    let fetchRequest: NSFetchRequest<CKMTwitterContact> = CKMTwitterContact.fetchRequest()
    let dataKeyPath = #keyPath(CKMTwitterContact.profileImageData)
    let predicate = NSPredicate(format: "\(dataKeyPath) = nil")
    fetchRequest.predicate = predicate

    do {
      return try context.fetch(fetchRequest)
    } catch {
      return []
    }
  }

  func asTwitterUser() -> TwitterUser {
    return TwitterUser(idStr: identityHash,
                       name: displayName,
                       screenName: displayScreenName,
                       description: nil,
                       url: nil,
                       verified: verifiedTwitterUser,
                       profileImageUrlHttps: nil,
                       profileImageData: profileImageData)
  }

  func configure(with contact: TwitterContactType, in context: NSManagedObjectContext) {
    self.identityHash = contact.identityHash
    self.displayName = contact.displayName ?? ""
    self.displayScreenName = contact.displayHandle.dropFirstCharacter(ifEquals: "@")
    self.profileImageData = contact.twitterUser.profileImageData
    self.verifiedTwitterUser = contact.twitterUser.verified
    switch contact.kind {
    case .invite, .generic: self.verificationStatus = .notVerified
    case .registeredUser: self.verificationStatus = .verified
    }
  }
}
