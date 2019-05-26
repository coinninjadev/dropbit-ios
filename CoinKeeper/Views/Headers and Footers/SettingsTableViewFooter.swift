//
//  SettingsTableViewFooter.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class SettingsTableViewFooter: UITableViewHeaderFooterView {

  @IBOutlet var _backgroundView: UIView!
  private var command: Command?

  @IBOutlet var deleteWalletButton: UIButton!

  @IBAction func executeCommand(_ sender: Any) {
    command?.execute()
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    _backgroundView.backgroundColor = Theme.Color.lightGrayBackground.color
    deleteWalletButton.titleLabel?.font = Theme.Font.deleteWalletTitle.font
    deleteWalletButton.setTitleColor(Theme.Color.red.color, for: .normal)
  }

  func load(with viewModel: SettingsHeaderFooterViewModel) {
    deleteWalletButton.setTitle(viewModel.title, for: .normal)
    self.command = viewModel.command
  }

}
