//
//  Array+Helpers.swift
//  DropBit
//
//  Created by Mitchell Malleo on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

extension Array {
  subscript(safe index: Int) -> Element? {
    return indices ~= index ? self[index] : nil
  }

  public mutating func safelyRemoveFirst() -> Element? {
    if self.isEmpty {
      return nil
    } else {
      return self.removeFirst()
    }
  }

}

extension Array {
  public func chunked(by chunkSize: Int) -> [[Element]] {
    guard self.isNotEmpty && chunkSize > 0 else { return [self] }
    return stride(from: 0, to: self.count, by: chunkSize).map {
      Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
    }
  }
}

extension Array {
  func appending(element: Element) -> [Element] {
    var selfCopy = self
    selfCopy.append(element)
    return selfCopy
  }
}

extension Array: Applicable {}

extension Array where Array.Element: Hashable {
  func asSet() -> Set<Element> {
    return Set(self)
  }

  func uniqued() -> [Element] {
    return Array(self.asSet())
  }
}
