//
//  CKMCounterparty+CoreDataProperties.swift
//  DropBit
//
//  Created by BJ Miller on 6/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//
//

import Foundation
import CoreData

extension CKMCounterparty {

  enum Kind: String {
    case `default`
    case referral
  }

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMCounterparty> {
    return NSFetchRequest<CKMCounterparty>(entityName: "CKMCounterparty")
  }

  @NSManaged public var name: String
  @NSManaged public var phoneNumbers: Set<CKMPhoneNumber>
  @NSManaged public var walletEntries: Set<CKMWalletEntry>
  @NSManaged public var kind: String?
  @NSManaged public var profileImageData: Data?

}

// MARK: Generated accessors for phoneNumbers
extension CKMCounterparty {

  @objc(addPhoneNumbersObject:)
  @NSManaged public func addToPhoneNumbers(_ value: CKMPhoneNumber)

  @objc(removePhoneNumbersObject:)
  @NSManaged public func removeFromPhoneNumbers(_ value: CKMPhoneNumber)

  @objc(addPhoneNumbers:)
  @NSManaged public func addToPhoneNumbers(_ values: Set<CKMPhoneNumber>)

  @objc(removePhoneNumbers:)
  @NSManaged public func removeFromPhoneNumbers(_ values: Set<CKMPhoneNumber>)

}
