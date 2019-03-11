//
//  DrawerCell.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class DrawerCell: UITableViewCell, Badgeable {

  // MARK: outlets
  @IBOutlet var iconImageView: UIImageView!
  @IBOutlet var titleLabel: UILabel!

  var badgeDisplayCriteria: BadgeInfo = [:]
  var badgeOffset: ViewOffset = .none

  // MARK: view instantiation
  override func awakeFromNib() {
    super.awakeFromNib()
    selectionStyle = .none
    titleLabel.font = Theme.Font.settingsTitle.font
    titleLabel.textColor = UIColor.white
    backgroundColor = Theme.Color.settingsDarkGray.color
  }

  func load(with data: DrawerData, badgeInfo: BadgeInfo) {
    iconImageView.image = data.image
    titleLabel.text = data.title
    badgeDisplayCriteria = data.badgeCriteria
    badgeOffset = data.badgeOffset
    updateBadge(with: badgeInfo)
  }

  var badgeTarget: UIView {
    return iconImageView
  }

}
