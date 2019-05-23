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
public class CKMTwitterContact: NSManagedObject {

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

  func asTwitterUser() -> TwitterUser {
    return TwitterUser(idStr: identityHash,
                       name: displayName,
                       screenName: displayScreenName,
                       description: nil,
                       url: nil,
                       profileImageUrlHttps: nil,
                       profileImageData: profileImageData)
  }

  private func configure(with contact: TwitterContactType, in context: NSManagedObjectContext) {
    self.identityHash = contact.identityHash
    self.displayName = contact.displayName ?? ""
    self.displayScreenName = contact.displayIdentity
    switch contact.kind {
    case .invite, .generic: self.verificationStatus = .notVerified
    case .registeredUser: self.verificationStatus = .verified
    }
  }
}
