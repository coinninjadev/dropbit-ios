//
//  SettingSwitchCell.swift
//  DropBit
//
//  Created by Ben Winters on 3/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol SettingSwitchCellDelegate: AnyObject {
  func settingSwitchCell(_ cell: SettingSwitchCell, didToggle isOn: Bool)
}

class SettingSwitchCell: UITableViewCell {

  weak var delegate: SettingSwitchCellDelegate?

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
    delegate?.settingSwitchCell(self, didToggle: sender.isOn)
  }

  // MARK: view instantiation
  override func awakeFromNib() {
    super.awakeFromNib()
    selectionStyle = .none
    backgroundColor = Theme.Color.lightGrayBackground.color

    settingSwitch.onTintColor = Theme.Color.primaryActionButton.color
    settingSwitch.isOn = false
  }

  func load(with viewModel: SettingsCellViewModel, delegate: SettingSwitchCellDelegate) {
    self.delegate = delegate
    titleLabel.attributedText = viewModel.type.attributedTitle

    switch viewModel.type {
    case .dustProtection(let isEnabled):
      settingSwitch.isOn = isEnabled
    default:
      settingSwitch.isOn = false
    }
  }

}
