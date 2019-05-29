//
//  SettingsBaseCell.swift
//  DropBit
//
//  Created by BJ Miller on 5/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SettingsBaseCell: UITableViewCell {
  // MARK: view instantiation
  override func awakeFromNib() {
    super.awakeFromNib()
    selectionStyle = .none
    backgroundColor = Theme.Color.lightGrayBackground.color
  }

  /// By default does nothing. Subclasses can override to perform custom loading.
  func load(with viewModel: SettingsCellViewModel) {

  }
}
