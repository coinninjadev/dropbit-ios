//
//  CKMLNAccount+CoreDataClass.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData

@objc(CKMLNAccount)
public class CKMLNAccount: NSManagedObject {

  public override func awakeFromInsert() {
    super.awakeFromInsert()
    setPrimitiveValue("", forKey: #keyPath(CKMLNAccount.id))
    setPrimitiveValue(0, forKey: #keyPath(CKMLNAccount.balance))
    setPrimitiveValue(0, forKey: #keyPath(CKMLNAccount.pendingIn))
    setPrimitiveValue(0, forKey: #keyPath(CKMLNAccount.pendingOut))
    setPrimitiveValue("", forKey: #keyPath(CKMLNAccount.address))
  }

  @nonobjc public class func fetchRequest() -> NSFetchRequest<CKMLNAccount> {
    return NSFetchRequest<CKMLNAccount>(entityName: "CKMLNAccount")
  }

  private convenience init(forWallet wallet: CKMWallet, insertInto context: NSManagedObjectContext) {
    self.init(insertInto: context)
    self.wallet = wallet
  }

  @discardableResult
  static func findOrCreate(forWallet wallet: CKMWallet, in context: NSManagedObjectContext) -> CKMLNAccount {
    if let foundBalance = find(forWallet: wallet, in: context) {
      return foundBalance
    } else {
      let account = CKMLNAccount(forWallet: wallet, insertInto: context)
      return account
    }
  }

  static func find(forWallet wallet: CKMWallet, in context: NSManagedObjectContext) -> CKMLNAccount? {
    let fetchRequest: NSFetchRequest<CKMLNAccount> = CKMLNAccount.fetchRequest()
    let walletPath = #keyPath(CKMLNAccount.wallet)
    fetchRequest.predicate = NSPredicate(format: "\(walletPath) == %@", wallet)
    fetchRequest.fetchLimit = 1

    do {
      let results = try context.fetch(fetchRequest)
      return results.first
    } catch {
      return nil
    }
  }

  func update(with response: LNAccountResponse) {
    self.id = response.id
    self.balance = response.balance
    self.pendingIn = response.pendingIn
    self.pendingOut = response.pendingOut
    self.address = response.address
  }

}
