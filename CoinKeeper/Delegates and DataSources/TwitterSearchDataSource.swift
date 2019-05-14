//
//  TwitterSearchDataSource.swift
//  DropBit
//
//  Created by BJ Miller on 5/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TwitterSearchDataSource: NSObject, UITableViewDataSource {
  private(set) var users: [TwitterUser] = []
  private weak var tableView: UITableView?

  init(tableView: UITableView) {
    self.tableView = tableView
  }

  func update(users: [TwitterUser]) {
    self.users = users
    tableView?.reloadData()
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return users.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeue(TwitterUserTableViewCell.self, for: indexPath)
    let user = users[indexPath.row]
    cell.load(with: user)
    return cell
  }
}
