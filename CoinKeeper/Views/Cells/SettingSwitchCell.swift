//
//  SettingSwitchCell.swift
//  DropBit
//
//  Created by Ben Winters on 3/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SettingSwitchCell: UITableViewCell {

  var viewModel: SettingsCellViewModel?

  @IBOutlet var settingSwitch: UISwitch!

  // MARK: outlets
  @IBOutlet var titleLabel: UILabel! {
    didSet {
      // These may be overridden by the SettingsCellViewModel
      titleLabel.font = Theme.Font.settingTitle.font
      titleLabel.textColor = Theme.Color.darkBlueText.color
    }
  }

  @IBAction func toggle(_ sender: UISwitch) {
    viewModel?.command?.execute()
  }

  // MARK: view instantiation
  override func awakeFromNib() {
    super.awakeFromNib()
    selectionStyle = .none
    backgroundColor = Theme.Color.lightGrayBackground.color

    settingSwitch.onTintColor = Theme.Color.primaryActionButton.color
    settingSwitch.isOn = false
  }

  func load(with viewModel: SettingsCellViewModel) {
    self.viewModel = viewModel
    titleLabel.attributedText = viewModel.type.attributedTitle
    self.settingSwitch.isOn = viewModel.type.switchIsOn
  }

}
