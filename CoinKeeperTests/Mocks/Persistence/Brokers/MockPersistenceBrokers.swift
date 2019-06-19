//
//  MockPersistenceBrokers.swift
//  DropBit
//
//  Created by Ben Winters on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

class MockPersistenceBrokerInputs {
  let keychain: PersistenceKeychainType
  let database: PersistenceDatabaseType
  let defaults: PersistenceUserDefaultsType
  init(keychain: PersistenceKeychainType,
       database: PersistenceDatabaseType,
       defaults: PersistenceUserDefaultsType) {
    self.keychain = keychain
    self.database = database
    self.defaults = defaults
  }
}

class MockPersistenceBrokers: PersistenceBrokersType {

  let activity: ActivityBrokerType
  let checkIn: CheckInBrokerType
  let device: DeviceBrokerType
  let invitation: InvitationBrokerType
  let migration: MigrationBrokerType
  let preferences: PreferencesBrokerType
  let transaction: TransactionBrokerType
  let user: UserBrokerType
  let wallet: WalletBrokerType

  init(mockActivityBroker: ActivityBrokerType,
       mockCheckInBroker: CheckInBrokerType,
       mockDeviceBroker: DeviceBrokerType,
       mockInvitationBroker: InvitationBrokerType,
       mockMigrationBroker: MigrationBrokerType,
       mockPreferencesBroker: PreferencesBrokerType,
       mockTransactionBroker: TransactionBrokerType,
       mockUserBroker: UserBrokerType,
       mockWalletBroker: WalletBrokerType) {
    self.activity = mockActivityBroker
    self.checkIn = mockCheckInBroker
    self.device = mockDeviceBroker
    self.invitation = mockInvitationBroker
    self.migration = mockMigrationBroker
    self.preferences = mockPreferencesBroker
    self.transaction = mockTransactionBroker
    self.user = mockUserBroker
    self.wallet = mockWalletBroker
  }

  init(inputs: MockPersistenceBrokerInputs,
       mockActivityBroker: ActivityBrokerType? = nil,
       mockCheckInBroker: CheckInBrokerType? = nil,
       mockDeviceBroker: DeviceBrokerType? = nil,
       mockInvitationBroker: InvitationBrokerType? = nil,
       mockMigrationBroker: MigrationBrokerType? = nil,
       mockPreferencesBroker: PreferencesBrokerType? = nil,
       mockTransactionBroker: TransactionBrokerType? = nil,
       mockUserBroker: UserBrokerType? = nil,
       mockWalletBroker: WalletBrokerType? = nil) {
    let keychain = inputs.keychain
    let database = inputs.database
    let defaults = inputs.defaults
    self.activity = mockActivityBroker ?? MockActivityBroker(keychain, database, defaults)
    self.checkIn = mockCheckInBroker ?? MockCheckInBroker(keychain, database, defaults)
    self.device = mockDeviceBroker ?? MockDeviceBroker(keychain, database, defaults)
    self.invitation = mockInvitationBroker ?? MockInvitationBroker(keychain, database, defaults)
    self.migration = mockMigrationBroker ?? MockMigrationBroker(keychain, database, defaults)
    self.preferences = mockPreferencesBroker ?? MockPreferencesBroker(keychain, database, defaults)
    self.transaction = mockTransactionBroker ?? MockTransactionBroker(keychain, database, defaults)
    self.user = mockUserBroker ?? MockUserBroker(keychain, database, defaults)
    self.wallet = mockWalletBroker ?? MockWalletBroker(keychain, database, defaults)
  }

  static func mockInputs() -> MockPersistenceBrokerInputs {
    let mockKeychain = MockPersistenceKeychainManager(store: MockKeychainAccessorType())
    return MockPersistenceBrokerInputs(keychain: mockKeychain,
                                       database: MockPersistenceDatabaseManager(),
                                       defaults: MockUserDefaultsManager()
    )
  }

}
