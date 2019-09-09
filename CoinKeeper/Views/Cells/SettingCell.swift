//
//  SettingCell.swift
//  DropBit
//
//  Created by Mitchell on 5/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SettingCell: SettingsBaseCell {

  // MARK: outlets
  @IBOutlet var titleLabel: SettingsCellTitleLabel!

  override func load(with viewModel: SettingsCellViewModel) {
    titleLabel.text = viewModel.type.titleText
  }
}
