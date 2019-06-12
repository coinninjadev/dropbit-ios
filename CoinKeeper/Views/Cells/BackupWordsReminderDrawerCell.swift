//
//  BackupWordsReminderDrawerCell.swift
//  DropBit
//
//  Created by BJ Miller on 11/14/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class BackupWordsReminderDrawerCell: UITableViewCell {

  @IBOutlet var backingView: UIView! {
    didSet {
      backingView.backgroundColor = .darkPeach
      backingView.applyCornerRadius(8)
    }
  }

  @IBOutlet var titleLabel: UILabel! {
    didSet {
      titleLabel.font = .medium(13)
      titleLabel.textColor = .whiteText
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    selectionStyle = .none
    backgroundColor = .clear
  }

  func load(with viewModel: DrawerData) {
    titleLabel.text = viewModel.title
  }

}
