//
//  SettingsViewController.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol SettingsViewControllerDelegate: ViewControllerDismissable {

  func verifyIfWordsAreBackedUp() -> Bool
  func dustProtectionIsEnabled() -> Bool
  func yearlyHighPushNotificationIsSubscribed() -> Bool

  func viewControllerDidRequestDeleteWallet(_ viewController: UIViewController,
                                            completion: @escaping () -> Void)
  func viewControllerDidConfirmDeleteWallet(_ viewController: UIViewController)
  func viewControllerDidSelectOpenSourceLicenses(_ viewController: UIViewController)
  func viewControllerDidSelectRecoveryWords(_ viewController: UIViewController)
  func viewController(_ viewController: UIViewController, didRequestOpenURL url: URL)
  func viewControllerResyncBlockchain(_ viewController: UIViewController)
  func viewController(_ viewController: UIViewController, didEnableDustProtection didEnable: Bool)
  func viewController(_ viewController: UIViewController, didEnableYearlyHighNotification didEnable: Bool)
}

class SettingsViewController: BaseViewController, StoryboardInitializable {

  var viewModel: SettingsViewModel!

  var coordinationDelegate: SettingsViewControllerDelegate? {
    return generalCoordinationDelegate as? SettingsViewControllerDelegate
  }

  @IBOutlet var closeButton: UIButton!
  @IBOutlet var settingsTableView: UITableView! {
    didSet {
      settingsTableView.backgroundColor = .clear
      settingsTableView.showsVerticalScrollIndicator = false
      settingsTableView.alwaysBounceVertical = false
    }
  }
  @IBOutlet var deleteWalletButton: UIButton! {
    didSet {
      deleteWalletButton.setTitleColor(Theme.Color.red.color, for: .normal)
      deleteWalletButton.titleLabel?.font = Theme.Font.deleteWalletTitle.font
      deleteWalletButton.setTitle("DELETE WALLET", for: .normal)
    }
  }
  @IBOutlet var resyncBlockchainButton: PrimaryActionButton!

  @IBAction func deleteWallet(_ sender: Any) {
    coordinationDelegate?.viewControllerDidRequestDeleteWallet(self, completion: {
      self.coordinationDelegate?.viewControllerDidConfirmDeleteWallet(self)
      self.coordinationDelegate?.viewControllerDidSelectClose(self)
    })
  }

  @IBAction func resyncBlockchain(_ sender: Any) {
    coordinationDelegate?.viewControllerResyncBlockchain(self)
  }

  @IBAction func close() {
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }

  static func newInstance(with delegate: SettingsViewControllerDelegate) -> SettingsViewController {
    let controller = SettingsViewController.makeFromStoryboard()
    controller.generalCoordinationDelegate = delegate
    controller.modalPresentationStyle = .formSheet
    return controller
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    viewModel = createViewModel()
    settingsTableView.registerNib(cellType: SettingCell.self)
    settingsTableView.registerNib(cellType: SettingsRecoveryWordsCell.self)
    settingsTableView.registerNib(cellType: SettingSwitchCell.self)
    settingsTableView.registerNib(cellType: SettingSwitchWithInfoCell.self)
    settingsTableView.registerHeaderFooter(headerFooterType: SettingsTableViewSectionHeader.self)
    settingsTableView.dataSource = self
    settingsTableView.delegate = self

    // Hide empty cell separators
    settingsTableView.tableFooterView = UIView(frame: CGRect.zero)
    settingsTableView.reloadData()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = true
  }

  private func isWalletBackedUp() -> Bool {
    return coordinationDelegate?.verifyIfWordsAreBackedUp() ?? false
  }

  private func createViewModel() -> SettingsViewModel {
    let sectionViewModels: [SettingsSectionViewModel]
      let walletSection = walletSectionViewModel()
      let licensesSection = SettingsSectionViewModel(
        headerViewModel: SettingsHeaderFooterViewModel(title: "LICENSES"),
        cellViewModels: [SettingsCellViewModel(type: .licenses, command: openSourceCommand)])
      sectionViewModels = [walletSection, licensesSection]

    return SettingsViewModel(sectionViewModels: sectionViewModels)
  }

  private func walletSectionViewModel() -> SettingsSectionViewModel {
    let recoveryWordsVM = SettingsCellViewModel(type: .recoveryWords(isWalletBackedUp()), command: recoveryWordsCommand)
    let dustProtectionEnabled = self.coordinationDelegate?.dustProtectionIsEnabled() ?? false
    let dustCellType = SettingsCellType.dustProtection(enabled: dustProtectionEnabled)
    let dustProtectionVM = SettingsCellViewModel(type: dustCellType, command: openURLCommand(for: dustCellType))

    let isYearlyHighPushEnabled = self.coordinationDelegate?.yearlyHighPushNotificationIsSubscribed() ?? false
    let yearlyHighType = SettingsCellType.yearlyHighPushNotification(enabled: isYearlyHighPushEnabled)
    let yearlyHighViewModel = SettingsCellViewModel(type: yearlyHighType, command: yearlyHighPriceCommand)
    return SettingsSectionViewModel(
      headerViewModel: SettingsHeaderFooterViewModel(title: "WALLET"),
      cellViewModels: [recoveryWordsVM, dustProtectionVM, yearlyHighViewModel])
  }

}

// MARK: - Command Actions

extension SettingsViewController {

  var openSourceCommand: Command {
    return Command(action: { [weak self] in
      guard let localSelf = self else { return }
      localSelf.coordinationDelegate?.viewControllerDidSelectOpenSourceLicenses(localSelf)
    })
  }

  var recoveryWordsCommand: Command {
    return Command(action: { [weak self] in
      guard let localSelf = self else { return }
      localSelf.coordinationDelegate?.viewControllerDidSelectRecoveryWords(localSelf)
    })
  }

  func openURLCommand(for type: SettingsCellType) -> Command {
    return Command(action: { [weak self] in
      guard let localSelf = self else { return }
      guard let coordinator = localSelf.coordinationDelegate else { return }
      let didEnable = !coordinator.dustProtectionIsEnabled()
      coordinator.viewController(localSelf, didEnableDustProtection: didEnable)
    })
  }

  var yearlyHighPriceCommand: Command {
    return Command(action: { [weak self] in
      guard let localSelf = self, let delegate = localSelf.coordinationDelegate else { return }
      let didEnable = !delegate.yearlyHighPushNotificationIsSubscribed()
      delegate.viewController(localSelf, didEnableYearlyHighNotification: didEnable)
    })
  }

}

extension SettingsViewController: SettingSwitchCellDelegate {
  func tableViewCellDidSelectInfoButton(_ cell: UITableViewCell, viewModel: SettingsCellViewModel?) {
    guard let vm = viewModel else { return }
    switch vm.type {
    case .dustProtection:
      guard let url = vm.type.url else { return }
      coordinationDelegate?.viewController(self, didRequestOpenURL: url)
    default: break
    }
  }
}
