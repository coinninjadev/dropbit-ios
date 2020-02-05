//
//  PersistenceUserDefaultsType.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 1/20/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol PersistenceUserDefaultsType: AnyObject {

  /// Avoid using the methods of UserDefaults directly,
  /// use the extension functions with CKUserDefaults.Key instead.
  var standardDefaults: UserDefaults { get }

  var configDefaults: UserDefaults { get }

  var useRegtest: Bool { get set }

  func deleteAll()
  func deleteWallet()
  func unverifyUser()

}

extension PersistenceUserDefaultsType {

  func double(for key: CKUserDefaults.Key) -> Double {
    return standardDefaults.double(forKey: key.defaultsString)
  }

  func set(_ doubleValue: Double, for key: CKUserDefaults.Key) {
    standardDefaults.set(doubleValue, forKey: key.defaultsString)
  }

  func integer(for key: CKUserDefaults.Key) -> Int {
    return standardDefaults.integer(forKey: key.defaultsString)
  }

  func set(_ integerValue: Int, for key: CKUserDefaults.Key) {
    standardDefaults.set(integerValue, forKey: key.defaultsString)
  }

  func string(for key: CKUserDefaults.Key) -> String? {
    return standardDefaults.string(forKey: key.defaultsString)
  }

  func array(for key: CKUserDefaults.Key) -> [Any]? {
    return standardDefaults.array(forKey: key.defaultsString)
  }

  func set(_ array: [String], for key: CKUserDefaults.Key) {
    standardDefaults.set(array, forKey: key.defaultsString)
  }

  func set(_ string: String, for key: CKUserDefaults.Key) {
    standardDefaults.set(string, forKey: key.defaultsString)
  }

  func set(_ stringValue: CKUserDefaults.Value, for key: CKUserDefaults.Key) {
    set(stringValue.defaultsString, for: key)
  }

  func set(stringValue: String, for key: CKUserDefaults.Key) {
    standardDefaults.set(stringValue, forKey: key.defaultsString)
  }

  func set(_ bool: Bool, for key: CKUserDefaults.Key) {
    standardDefaults.set(bool, forKey: key.defaultsString)
  }

  func bool(for key: CKUserDefaults.Key) -> Bool {
    return standardDefaults.bool(forKey: key.defaultsString)
  }

  func set(_ date: Date, for key: CKUserDefaults.Key) {
    standardDefaults.set(date, forKey: key.defaultsString)
  }

  func date(for key: CKUserDefaults.Key) -> Date? {
    return standardDefaults.object(forKey: key.defaultsString) as? Date
  }

  func object(for key: CKUserDefaults.Key) -> Any? {
    return standardDefaults.object(forKey: key.defaultsString)
  }

  func set(_ object: Any?, for key: CKUserDefaults.Key) {
    standardDefaults.set(object, forKey: key.defaultsString)
  }

  func value(for key: CKUserDefaults.Key) -> Any? {
    return standardDefaults.value(forKey: key.defaultsString)
  }

  func setValue(_ value: Any?, for key: CKUserDefaults.Key) {
    standardDefaults.setValue(value, forKey: key.defaultsString)
  }

  func removeValue(for key: CKUserDefaults.Key) {
    standardDefaults.set(nil, forKey: key.defaultsString)
  }

  func removeValues(forKeys keys: [CKUserDefaults.Key]) {
    keys.forEach { removeValue(for: $0) }
  }

}
