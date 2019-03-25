//
//  SettingsViewController+TableView.swift
//  DropBit
//
//  Created by Ben Winters on 3/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension SettingsViewController: SettingSwitchCellDelegate {
  func settingSwitchCell(_ cell: SettingSwitchCell, didToggle isOn: Bool) {
    self.coordinationDelegate?.viewControllerDidChangeDustProtection(self, shouldEnable: isOn)
  }
}

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
    switch cellVM.type {
    case .dustProtection:
      guard let cell = tableView.dequeueReusableCell(
        withIdentifier: SettingSwitchCell.reuseIdentifier,
        for: indexPath) as? SettingSwitchCell
        else { return UITableViewCell() }

      cell.load(with: cellVM, delegate: self)
      return cell

    default:
      guard let cell = tableView.dequeueReusableCell(
        withIdentifier: SettingCell.reuseIdentifier,
        for: indexPath) as? SettingCell
        else { return UITableViewCell() }

      cell.load(with: cellVM)
      return cell
    }

  }

}

extension SettingsViewController: UITableViewDelegate {

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cellVM = cellViewModel(for: indexPath)
    cellVM?.command?.execute()
  }

  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    let sectionVM = sectionViewModel(for: section)
    return (sectionVM?.footerViewModel != nil) ? 100.0 : 0
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    let sectionVM = sectionViewModel(for: section)
    return (sectionVM?.headerViewModel != nil) ? 40 : 0
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

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    guard let footerModel = sectionViewModel(for: section)?.footerViewModel else { return nil }
    guard let footerView: SettingsTableViewFooter = tableView.dequeueReusableHeaderFooterView(
      withIdentifier: SettingsTableViewFooter.reuseIdentifier) as? SettingsTableViewFooter else {
        return nil
    }

    footerView.load(with: footerModel)

    return footerView
  }

}
