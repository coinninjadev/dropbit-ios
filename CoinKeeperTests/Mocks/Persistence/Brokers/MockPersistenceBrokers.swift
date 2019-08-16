//
//  MockPersistenceBrokers.swift
//  DropBit
//
//  Created by Ben Winters on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
@testable import DropBit

protocol PersistenceBrokerInputsType: AnyObject {
  var keychain: PersistenceKeychainType { get }
  var database: PersistenceDatabaseType { get }
  var defaults: PersistenceUserDefaultsType { get }
}

class PersistenceBrokerInputs: PersistenceBrokerInputsType {
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

class MockPersistenceBrokerInputs: PersistenceBrokerInputsType {

  let mockKeychain: MockPersistenceKeychainManager
  let mockDatabase: MockPersistenceDatabaseManager
  let mockDefaults: MockUserDefaultsManager

  init(mockKeychain: MockPersistenceKeychainManager,
       mockDatabase: MockPersistenceDatabaseManager,
       mockDefaults: MockUserDefaultsManager) {
    self.mockKeychain = mockKeychain
    self.mockDatabase = mockDatabase
    self.mockDefaults = mockDefaults
  }

  var keychain: PersistenceKeychainType { return mockKeychain }
  var database: PersistenceDatabaseType { return mockDatabase }
  var defaults: PersistenceUserDefaultsType { return mockDefaults }

  static func newInstance() -> MockPersistenceBrokerInputs {
    let mockKeychain = MockPersistenceKeychainManager(store: MockKeychainAccessorType())
    return MockPersistenceBrokerInputs(mockKeychain: mockKeychain,
                                       mockDatabase: MockPersistenceDatabaseManager(),
                                       mockDefaults: MockUserDefaultsManager()
    )
  }

}

class MockPersistenceBrokers: PersistenceBrokersType {

  let mockActivity: MockActivityBroker
  let mockCheckIn: MockCheckInBroker
  let mockDevice: MockDeviceBroker
  let mockInvitation: MockInvitationBroker
  let mockMigration: MockMigrationBroker
  let mockPreferences: MockPreferencesBroker
  let mockTransaction: MockTransactionBroker
  let mockUser: MockUserBroker
  let mockWallet: MockWalletBroker
  let mockLightning: MockLightningBroker

  init(activity: MockActivityBroker,
       checkIn: MockCheckInBroker,
       device: MockDeviceBroker,
       invitation: MockInvitationBroker,
       migration: MockMigrationBroker,
       preferences: MockPreferencesBroker,
       transaction: MockTransactionBroker,
       user: MockUserBroker,
       wallet: MockWalletBroker,
       lightning: MockLightningBroker) {
    self.mockActivity = activity
    self.mockCheckIn = checkIn
    self.mockDevice = device
    self.mockInvitation = invitation
    self.mockMigration = migration
    self.mockPreferences = preferences
    self.mockTransaction = transaction
    self.mockUser = user
    self.mockWallet = wallet
    self.mockLightning = lightning
  }

  init(inputs: PersistenceBrokerInputsType) {
    let keychain = inputs.keychain
    let database = inputs.database
    let defaults = inputs.defaults
    self.mockActivity = MockActivityBroker(keychain, database, defaults)
    self.mockCheckIn = MockCheckInBroker(keychain, database, defaults)
    self.mockDevice = MockDeviceBroker(keychain, database, defaults)
    self.mockInvitation = MockInvitationBroker(keychain, database, defaults)
    self.mockMigration = MockMigrationBroker(keychain, database, defaults)
    self.mockPreferences = MockPreferencesBroker(keychain, database, defaults)
    self.mockTransaction = MockTransactionBroker(keychain, database, defaults)
    self.mockUser = MockUserBroker(keychain, database, defaults)
    self.mockWallet = MockWalletBroker(keychain, database, defaults)
    self.mockLightning = MockLightningBroker(keychain, database, defaults)
  }

  var activity: ActivityBrokerType { return mockActivity }
  var checkIn: CheckInBrokerType { return mockCheckIn }
  var device: DeviceBrokerType { return mockDevice }
  var invitation: InvitationBrokerType { return mockInvitation }
  var migration: MigrationBrokerType { return mockMigration }
  var preferences: PreferencesBrokerType { return mockPreferences }
  var transaction: TransactionBrokerType { return mockTransaction }
  var user: UserBrokerType { return mockUser }
  var wallet: WalletBrokerType { return mockWallet }
  var lightning: LightningBrokerType { return mockLightning }

}
