//
//  SettingCell.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SettingCell: UITableViewCell {

  // MARK: outlets
  @IBOutlet var chevronImageView: UIImageView!
  @IBOutlet var titleLabel: UILabel! {
    didSet {
      // These may be overridden by the SettingsCellViewModel
      titleLabel.font = Theme.Font.settingTitle.font
      titleLabel.textColor = Theme.Color.darkBlueText.color
    }
  }

  // MARK: view instantiation
  override func awakeFromNib() {
    super.awakeFromNib()
    selectionStyle = .none
    backgroundColor = Theme.Color.lightGrayBackground.color
  }

  func load(with viewModel: SettingsCellViewModel) {
    titleLabel.attributedText = viewModel.type.attributedTitle
    chevronImageView.isHidden = !viewModel.type.shouldShowDisclosureIndicator
  }

}
