//
//  SettingsTableViewSectionHeader.swift
//  CoinKeeper
//
//  Created by Ben Winters on 6/25/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SettingsTableViewSectionHeader: UITableViewHeaderFooterView {

  @IBOutlet var titleLabel: UILabel!

  func load(with viewModel: SettingsHeaderFooterViewModel) {
    titleLabel.text = viewModel.title
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    titleLabel.font = CKFont.semiBold(14)
    titleLabel.textColor = .darkBlueText
  }
}
