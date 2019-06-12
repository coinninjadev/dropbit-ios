//
//  SettingsRecoveryWordsCell.swift
//  DropBit
//
//  Created by BJ Miller on 5/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SettingsRecoveryWordsCell: SettingsBaseCell {

  @IBOutlet var titleLabel: SettingsCellTitleLabel!
  @IBOutlet var notBackedUpLabel: SettingsCellTitleLabel! {
    didSet {
      notBackedUpLabel.textColor = .darkPeach
    }
  }

  override func load(with viewModel: SettingsCellViewModel) {
    titleLabel.text = viewModel.type.titleText
    notBackedUpLabel.text = viewModel.type.secondaryTitleText
  }

}
