//
//  SettingSwitchCell.swift
//  DropBit
//
//  Created by Ben Winters on 3/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol SettingSwitchCellDelegate: AnyObject {
  func tableViewCellDidSelectInfoButton(_ cell: UITableViewCell, viewModel: SettingsCellViewModel?)
}

class SettingSwitchCell: SettingsBaseCell {

  var viewModel: SettingsCellViewModel?
  weak var delegate: SettingSwitchCellDelegate?

  // MARK: outlets
  @IBOutlet var titleLabel: SettingsCellTitleLabel!
  @IBOutlet var settingSwitch: UISwitch!
  @IBOutlet var infoButton: UIButton!

  @IBAction func toggle(_ sender: UISwitch) {
    viewModel?.command?.execute()
  }

  @IBAction func showInfo() {
    delegate?.tableViewCellDidSelectInfoButton(self, viewModel: viewModel)
  }

  // MARK: view instantiation
  override func awakeFromNib() {
    super.awakeFromNib()
    settingSwitch.onTintColor = Theme.Color.primaryActionButton.color
    settingSwitch.isOn = false
  }

  override func load(with viewModel: SettingsCellViewModel) {
    self.viewModel = viewModel
    titleLabel.text = viewModel.type.titleText
    self.settingSwitch.isOn = viewModel.type.switchIsOn
  }

}
