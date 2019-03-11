//
//  UITableView+ReusableView.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UITableView {
  func registerNib<T: UITableViewCell>(cellType: T.Type) {
    self.register(cellType.nib(), forCellReuseIdentifier: cellType.reuseIdentifier)
  }

  func registerHeaderFooter<T: UITableViewHeaderFooterView>(headerFooterType: T.Type) {
    self.register(headerFooterType.nib(), forHeaderFooterViewReuseIdentifier: headerFooterType.reuseIdentifier)
  }

  func dequeue<T: UITableViewCell>(_: T.Type, for indexPath: IndexPath) -> T {
    guard let cell = dequeueReusableCell(withIdentifier: String(describing: T.self), for: indexPath) as? T
      else { fatalError("Could not deque cell with type \(T.self)") }

    return cell
  }
}
