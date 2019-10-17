//
//  SettingsWithInfoCell.swift
//  DropBit
//
//  Created by BJ Miller on 10/17/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SettingsWithInfoCell: SettingsBaseCell {

  var viewModel: SettingsCellViewModel?

  // MARK: outlets
  @IBOutlet var titleLabel: SettingsCellTitleLabel!
  @IBOutlet var infoButton: UIButton!

  // MARK: actions
  @IBAction func showInfo() {
    viewModel?.showInfo()
  }

  override func load(with viewModel: SettingsCellViewModel) {
    self.viewModel = viewModel
    titleLabel.text = viewModel.type.titleText
  }

}
