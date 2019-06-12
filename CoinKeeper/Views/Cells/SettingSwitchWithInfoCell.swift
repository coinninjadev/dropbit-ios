//
//  SettingSwitchWithInfoCell.swift
//  DropBit
//
//  Created by Ben Winters on 3/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SettingSwitchWithInfoCell: SettingSwitchCell {

  // MARK: outlets
  @IBOutlet var infoButton: UIButton!

  // MARK: actions
  @IBAction func showInfo() {
    viewModel?.showInfo()
  }
}
