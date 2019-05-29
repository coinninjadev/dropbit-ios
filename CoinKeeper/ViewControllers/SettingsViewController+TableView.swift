//
//  SettingsViewController+TableView.swift
//  DropBit
//
//  Created by Ben Winters on 3/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension SettingsViewController: UITableViewDataSource {

  func sectionViewModel(for section: Int) -> SettingsSectionViewModel? {
    return self.viewModel.sectionViewModels[safe: section]
  }

  func cellViewModel(for indexPath: IndexPath) -> SettingsCellViewModel? {
    guard let sectionVM = sectionViewModel(for: indexPath.section) else { return nil }
    return sectionVM.cellViewModels[safe: indexPath.row]
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return self.viewModel.sectionViewModels.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.sectionViewModels[safe: section]?.cellViewModels.count ?? 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cellVM = cellViewModel(for: indexPath) else { return UITableViewCell() }
    let cell: SettingsBaseCell

    switch cellVM.type {
    case .dustProtection:
      cell = tableView.dequeue(SettingSwitchWithInfoCell.self, for: indexPath)
      (cell as? SettingSwitchWithInfoCell)?.delegate = self
    case .recoveryWords:
      cell = tableView.dequeue(SettingsRecoveryWordsCell.self, for: indexPath)
    default:
      cell = tableView.dequeue(SettingCell.self, for: indexPath)
    }

    cell.load(with: cellVM)
    return cell
  }
}

extension SettingsViewController: UITableViewDelegate {

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cellVM = cellViewModel(for: indexPath) else { return }
    guard let coordinator = coordinationDelegate else { return }
    switch cellVM.type {
    case .dustProtection:
      let didEnable = !coordinator.dustProtectionIsEnabled()
      coordinationDelegate?.viewController(self, didEnableDustProtection: didEnable)
    default:
      cellVM.command?.execute()
    }
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    let sectionVM = sectionViewModel(for: section)
    return (sectionVM?.headerViewModel != nil) ? 60 : 0
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60.0
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let headerModel = sectionViewModel(for: section)?.headerViewModel else { return nil }
    guard let headerView = tableView.dequeueReusableHeaderFooterView(
      withIdentifier: SettingsTableViewSectionHeader.reuseIdentifier) as? SettingsTableViewSectionHeader else {
        return nil
    }

    headerView.load(with: headerModel)

    return headerView
  }
}
