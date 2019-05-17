//
//  TwitterUserTableViewCell.swift
//  DropBit
//
//  Created by BJ Miller on 5/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TwitterUserTableViewCell: UITableViewCell {

  @IBOutlet var avatarImageView: UIImageView!
  @IBOutlet var nameLabel: ContactCellPrimaryLabel!
  @IBOutlet var screenNameLabel: ContactCellSecondaryLabel!
  @IBOutlet var dropbitImageView: UIImageView!

  func load(with user: TwitterUser) {
    avatarImageView.image = user.profileImageData.flatMap { UIImage(data: $0) }
    avatarImageView.applyCornerRadius(avatarImageView.frame.width / 2.0)
    nameLabel.text = user.name
    screenNameLabel.text = user.formattedScreenName
  }
}
