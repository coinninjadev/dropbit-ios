//
//  SettingSwitchWithInfoCell.swift
//  DropBit
//
//  Created by Ben Winters on 3/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol SettingSwitchCellDelegate: AnyObject {
  func tableViewCellDidSelectInfoButton(_ cell: UITableViewCell, viewModel: SettingsCellViewModel?)
}

class SettingSwitchWithInfoCell: SettingSwitchCell {

  weak var delegate: SettingSwitchCellDelegate?

  // MARK: outlets
  @IBOutlet var infoButton: UIButton!

  @IBAction func showInfo() {
    delegate?.tableViewCellDidSelectInfoButton(self, viewModel: viewModel)
  }
}
