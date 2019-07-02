//
//  SettingsViewController.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol SettingsViewControllerDelegate: ViewControllerDismissable, ViewControllerURLDelegate {

  func verifyIfWordsAreBackedUp() -> Bool
  func dustProtectionIsEnabled() -> Bool
  func yearlyHighPushNotificationIsSubscribed() -> Bool

  func viewControllerDidRequestDeleteWallet(_ viewController: UIViewController,
                                            completion: @escaping () -> Void)
  func viewControllerDidConfirmDeleteWallet(_ viewController: UIViewController)
  func viewControllerDidSelectOpenSourceLicenses(_ viewController: UIViewController)
  func viewControllerDidSelectRecoveryWords(_ viewController: UIViewController)
  func viewControllerDidSelectAdjustableFees(_ viewController: UIViewController)
  func viewControllerResyncBlockchain(_ viewController: UIViewController)
  func viewController(_ viewController: UIViewController, didEnableDustProtection didEnable: Bool)
  func viewController(_ viewController: UIViewController, didEnableYearlyHighNotification didEnable: Bool, completion: @escaping () -> Void)
}

class SettingsViewController: BaseViewController, StoryboardInitializable {

  var viewModel: SettingsViewModel!

  var coordinationDelegate: SettingsViewControllerDelegate? {
    return generalCoordinationDelegate as? SettingsViewControllerDelegate
  }

  @IBOutlet var settingsTableView: UITableView! {
    didSet {
      settingsTableView.backgroundColor = .clear
      settingsTableView.showsVerticalScrollIndicator = false
      settingsTableView.alwaysBounceVertical = false
    }
  }
  @IBOutlet var deleteWalletButton: UIButton! {
    didSet {
      deleteWalletButton.setTitleColor(.darkPeach, for: .normal)
      deleteWalletButton.titleLabel?.font = .medium(15)
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

  @objc func close() {
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

    setNavBarTitle()
    navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "close"), style: .plain, target: self, action: #selector(self.close))

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
    settingsTableView.reloadData()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    setNavBarTitle()
  }

  private func setNavBarTitle() {
    self.navigationItem.title = "SETTINGS"
  }

  private func isWalletBackedUp() -> Bool {
    return coordinationDelegate?.verifyIfWordsAreBackedUp() ?? false
  }

  private func createViewModel() -> SettingsViewModel {
    let sectionViewModels: [SettingsSectionViewModel]
    let walletSection = walletSectionViewModel()
    let licensesType = SettingsCellType.licenses { [weak self] in
      guard let localSelf = self else { return }
      localSelf.coordinationDelegate?.viewControllerDidSelectOpenSourceLicenses(localSelf)
    }
    let licensesSection = SettingsSectionViewModel(
      headerViewModel: SettingsHeaderFooterViewModel(title: "LICENSES"),
      cellViewModels: [SettingsCellViewModel(type: licensesType)])
    sectionViewModels = [walletSection, licensesSection]

    return SettingsViewModel(sectionViewModels: sectionViewModels)
  }

  private func walletSectionViewModel() -> SettingsSectionViewModel {
    let recoveryWordsType = SettingsCellType.recoveryWords(isWalletBackedUp()) { [weak self] in
      guard let localSelf = self else { return }
      localSelf.coordinationDelegate?.viewControllerDidSelectRecoveryWords(localSelf)
    }
    let recoveryWordsVM = SettingsCellViewModel(type: recoveryWordsType)

    let dustProtectionEnabled = self.coordinationDelegate?.dustProtectionIsEnabled() ?? false
    let dustCellType = SettingsCellType.dustProtection(
      enabled: dustProtectionEnabled,
      infoAction: { [weak self] (type: SettingsCellType) in
        guard let localSelf = self, let url = type.url else { return }
        localSelf.coordinationDelegate?.viewController(localSelf, didRequestOpenURL: url)
      },
      onChange: { [weak self] (didEnable: Bool) in
        guard let localSelf = self else { return }
        localSelf.coordinationDelegate?.viewController(localSelf, didEnableDustProtection: didEnable)
      }
    )
    let dustProtectionVM = SettingsCellViewModel(type: dustCellType)

    let isYearlyHighPushEnabled = self.coordinationDelegate?.yearlyHighPushNotificationIsSubscribed() ?? false
    let yearlyHighType = SettingsCellType.yearlyHighPushNotification(enabled: isYearlyHighPushEnabled) { [weak self] (didEnable: Bool) in
      guard let localSelf = self else { return }
      localSelf.coordinationDelegate?.viewController(
        localSelf,
        didEnableYearlyHighNotification: didEnable,
        completion: { [weak self] in
          guard let localSelf = self else { return }
          localSelf.viewModel = localSelf.createViewModel()
          localSelf.settingsTableView.reloadData()
        }
      )
    }
    let yearlyHighVM = SettingsCellViewModel(type: yearlyHighType)

    let adjustableFeesAction: BasicAction = { [weak self] in
      guard let localSelf = self else { return }
      localSelf.coordinationDelegate?.viewControllerDidSelectAdjustableFees(localSelf)
    }
    let adjustableFeesVM = SettingsCellViewModel(type: .adjustableFees(action: adjustableFeesAction))

    return SettingsSectionViewModel(
      headerViewModel: SettingsHeaderFooterViewModel(title: "WALLET"),
      cellViewModels: [recoveryWordsVM, dustProtectionVM, yearlyHighVM, adjustableFeesVM])
  }

}
