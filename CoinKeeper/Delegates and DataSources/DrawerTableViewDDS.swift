//
//  DrawerTableViewDDS.swift
//  DropBit
//
//  Created by Mitchell Malleo on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

struct DrawerData {
  enum Kind {
    case backupWords
    case getBitcoin
    case settings
    case verify
    case spend
    case support
    case earn
  }

  var image: UIImage?
  var title: String
  var kind: Kind
  var badgeCriteria: BadgeInfo
  var badgeOffset: ViewOffset

  init(image: UIImage?, title: String, kind: Kind, badgeCriteria: BadgeInfo = [:], badgeOffset: ViewOffset = .none) {
    self.image = image
    self.title = title
    self.kind = kind
    self.badgeCriteria = badgeCriteria
    self.badgeOffset = badgeOffset
  }

}

class DrawerTableViewDDS: NSObject, UITableViewDelegate, UITableViewDataSource {

  /// Set this before calling reloadData. It should be retained for subsequent reloads until the next badge update is received.
  internal var latestBadgeInfo: BadgeInfo = [:]

  var settingsData: [DrawerData] = []
  private var settingsActionHandler: (DrawerData.Kind) -> Void
  weak var currencyValueManager: CurrencyValueDataSourceType? // weakly held to guard against potential retain cycles

  init(settingsActionHandler: @escaping (DrawerData.Kind) -> Void) {
    self.settingsActionHandler = settingsActionHandler
    super.init()
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return settingsData.count
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 100.0
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 80.0
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let settingData = settingsData[safe: indexPath.row] else {
      return settingsActionHandler(.support)
    }

    settingsActionHandler(settingData.kind)
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let drawerTableViewHeader = tableView.dequeueReusableHeaderFooterView(
      withIdentifier: DrawerTableViewHeader.reuseIdentifier) as? DrawerTableViewHeader else {
        return nil
    }

    drawerTableViewHeader.currencyValueManager = currencyValueManager

    return drawerTableViewHeader
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let data = settingsData[safe: indexPath.row] else { fatalError("settings data missing") }

    switch data.kind {
    case .backupWords:
      let cell = tableView.dequeue(BackupWordsReminderDrawerCell.self, for: indexPath)
      cell.load(with: data)
      return cell
    default:
      let cell = tableView.dequeue(DrawerCell.self, for: indexPath)
      cell.load(with: data, badgeInfo: self.latestBadgeInfo)
      return cell
    }
  }
}
