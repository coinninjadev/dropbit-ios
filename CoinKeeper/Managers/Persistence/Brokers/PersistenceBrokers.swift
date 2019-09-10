//
//  PersistenceBrokers.swift
//  DropBit
//
//  Created by Ben Winters on 6/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

class PersistenceBrokers: PersistenceBrokersType {

  let activity: ActivityBrokerType
  let checkIn: CheckInBrokerType
  let device: DeviceBrokerType
  let invitation: InvitationBrokerType
  let migration: MigrationBrokerType
  let preferences: PreferencesBrokerType
  let transaction: TransactionBrokerType
  let user: UserBrokerType
  let wallet: WalletBrokerType
  let lightning: LightningBrokerType

  init(keychainManager keychain: PersistenceKeychainType,
       databaseManager database: PersistenceDatabaseType,
       userDefaultsManager defaults: PersistenceUserDefaultsType) {
    self.activity = ActivityBroker(keychainManager: keychain, databaseManager: database, userDefaultsManager: defaults)
    self.checkIn = CheckInBroker(keychainManager: keychain, databaseManager: database, userDefaultsManager: defaults)
    self.device = DeviceBroker(keychainManager: keychain, databaseManager: database, userDefaultsManager: defaults)
    self.invitation = InvitationBroker(keychainManager: keychain, databaseManager: database, userDefaultsManager: defaults)
    self.migration = MigrationBroker(keychainManager: keychain, databaseManager: database, userDefaultsManager: defaults)
    self.preferences = PreferencesBroker(keychainManager: keychain, databaseManager: database, userDefaultsManager: defaults)
    self.transaction = TransactionBroker(keychainManager: keychain, databaseManager: database, userDefaultsManager: defaults)
    self.user = UserBroker(keychainManager: keychain, databaseManager: database, userDefaultsManager: defaults)
    self.wallet = WalletBroker(keychainManager: keychain, databaseManager: database, userDefaultsManager: defaults)
    self.lightning = LightningBroker(keychainManager: keychain, databaseManager: database, userDefaultsManager: defaults)
  }

}
