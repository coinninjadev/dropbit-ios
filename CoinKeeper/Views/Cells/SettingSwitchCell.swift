//
//  SettingSwitchCell.swift
//  DropBit
//
//  Created by BJ Miller on 5/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SettingSwitchCell: SettingsBaseCell {

  var viewModel: SettingsCellViewModel?

  // MARK: outlets
  @IBOutlet var titleLabel: SettingsCellTitleLabel!
  @IBOutlet var settingSwitch: UISwitch!

  // MARK: view instantiation
  override func awakeFromNib() {
    super.awakeFromNib()
    settingSwitch.onTintColor = .primaryActionButton
    settingSwitch.isOn = false
  }

  @IBAction func toggle(_ sender: UISwitch) {
    viewModel?.command?.execute()
  }

  override func load(with viewModel: SettingsCellViewModel) {
    self.viewModel = viewModel
    titleLabel.text = viewModel.type.titleText
    self.settingSwitch.isOn = viewModel.type.switchIsOn
  }
}
