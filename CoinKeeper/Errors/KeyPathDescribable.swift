//
//  KeyPathDescribable.swift
//  DropBit
//
//  Created by Ben Winters on 10/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

/// Conformers should be a string-backed enum
public protocol KeyPathDescribable: CustomStringConvertible, RawRepresentable {
  /// The object type that defines the keys represented by this enum
  associatedtype ObjectType
}

extension KeyPathDescribable where Self.RawValue == String {

  public var description: String {
    return self.rawValue
  }

  public var typeDescription: String {
    return String(describing: ObjectType.self)
  }

  public var path: String {
    return "\(self.typeDescription).\(self.description)"
  }

}
