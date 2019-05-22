//
//  CKMUser+CoreDataClass.swift
//  CoinKeeper
//
//  Created by Ben Winters on 5/11/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CKMUser)
public class CKMUser: NSManagedObject {

  public override func awakeFromInsert() {
    super.awakeFromInsert()
    setPrimitiveValue("", forKey: #keyPath(CKMUser.id))
  }

  private convenience init(id: String, insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    self.id = id
  }

  /// Converts the stored string, provided by the server, into an enum for local use
  var verificationStatusCase: UserVerificationStatus {
    return verificationStatus.flatMap { UserVerificationStatus(rawValue: $0) } ?? .unverified
  }

  static func find(in context: NSManagedObjectContext) -> CKMUser? {
    let fetchRequest: NSFetchRequest<CKMUser> = CKMUser.fetchRequest()
    fetchRequest.fetchLimit = 1

    var user: CKMUser?
    do {
      let results = try context.fetch(fetchRequest)
      user = results.first
    } catch {
      user = nil
    }
    return user
  }

  /// Ensures that only one User is created since there is no predicate on the find(in:) function
  static func updateOrCreate(with id: String, in context: NSManagedObjectContext) -> CKMUser {
    if let user = find(in: context) {
      user.id = id
      return user
    } else {
      return CKMUser(id: id, insertInto: context)
    }
  }

}
