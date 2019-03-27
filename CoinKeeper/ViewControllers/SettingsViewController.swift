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

  func viewControllerDidRequestDeleteWallet(_ viewController: UIViewController,
                                            completion: @escaping () -> Void)
  func viewControllerDidConfirmDeleteWallet(_ viewController: UIViewController)
  func viewControllerDidSelectOpenSourceLicenses(_ viewController: UIViewController)
  func viewControllerDidSelectRecoveryWords(_ viewController: UIViewController)
  func viewControllerDidRequestOpenURL(_ viewController: UIViewController, url: URL)
  func viewControllerResyncBlockchain(_ viewController: UIViewController)
  func viewControllerSendDebuggingInfo(_ viewController: UIViewController)
  func viewControllerDidChangeDustProtection(_ viewController: UIViewController, shouldEnable: Bool)
}

enum SettingsViewControllerMode: String {
  case settings
  case support
}

class SettingsViewController: BaseViewController, StoryboardInitializable {

  var mode: SettingsViewControllerMode = .settings
  var viewModel: SettingsViewModel!

  var coordinationDelegate: SettingsViewControllerDelegate? {
    return generalCoordinationDelegate as? SettingsViewControllerDelegate
  }

  @IBOutlet var settingsTitleLabel: UILabel! {
    didSet {
      settingsTitleLabel.font = Theme.Font.onboardingSubtitle.font
      settingsTitleLabel.textColor = Theme.Color.darkBlueText.color
    }
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
      deleteWalletButton.setTitleColor(Theme.Color.errorRed.color, for: .normal)
      deleteWalletButton.titleLabel?.font = Theme.Font.deleteWalletTitle.font
      deleteWalletButton.setTitle("DELETE WALLET", for: .normal)
    }
  }
  @IBOutlet var resyncBlockchainButton: PrimaryActionButton!
  @IBOutlet var sendDebuggingInfoButton: PrimaryActionButton! {
    didSet {
      sendDebuggingInfoButton.setTitle("SEND DEBUG INFO", for: .normal)
    }
  }

  @IBAction func deleteWallet(_ sender: Any) {
    coordinationDelegate?.viewControllerDidRequestDeleteWallet(self, completion: {
      self.coordinationDelegate?.viewControllerDidConfirmDeleteWallet(self)
      self.coordinationDelegate?.viewControllerDidSelectClose(self)
    })
  }

  @IBAction func resyncBlockchain(_ sender: Any) {
    coordinationDelegate?.viewControllerResyncBlockchain(self)
  }

  @IBAction func sendDebuggingInfo(_ sender: Any) {
    coordinationDelegate?.viewControllerSendDebuggingInfo(self)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initalize()
  }

  private func initalize() {
    modalPresentationStyle = .formSheet
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    updateUIForMode()
    viewModel = createViewModel()
    settingsTableView.registerNib(cellType: SettingCell.self)
    settingsTableView.registerNib(cellType: SettingSwitchCell.self)
    settingsTableView.registerHeaderFooter(headerFooterType: SettingsTableViewFooter.self)
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

  private func backedUpWords() -> Bool {
    return coordinationDelegate?.verifyIfWordsAreBackedUp() ?? false
  }

  private func createViewModel() -> SettingsViewModel {
    let sectionViewModels: [SettingsSectionViewModel]
    switch self.mode {
    case .settings:
      let walletSection = walletSectionViewModel()
      let licensesSection = SettingsSectionViewModel(headerViewModel: SettingsHeaderFooterViewModel(title: "LICENSES", command: nil),
                                                     cellViewModels: [SettingsCellViewModel(type: .licenses, command: openSourceCommand)],
                                                     footerViewModel: nil)
      sectionViewModels = [walletSection, licensesSection]

    case .support:
      let types: [SettingsCellType] = [.faqs, .contactUs, .termsOfUse, .privacyPolicy]
      let cellViewModels = types.map { SettingsCellViewModel(type: $0, command: self.openURLCommand(for: $0)) }
      sectionViewModels = [
        SettingsSectionViewModel(headerViewModel: SettingsHeaderFooterViewModel(title: "SUPPORT", command: nil),
                                 cellViewModels: cellViewModels,
                                 footerViewModel: nil)
      ]

    }

    return SettingsViewModel(sectionViewModels: sectionViewModels)
  }

  private func walletSectionViewModel() -> SettingsSectionViewModel {
    let recoveryWordsVM = SettingsCellViewModel(type: .recoveryWords(backedUpWords()), command: recoveryWordsCommand)
    let dustProtectionEnabled = self.coordinationDelegate?.dustProtectionIsEnabled() ?? false
    let dustCellType = SettingsCellType.dustProtection(enabled: dustProtectionEnabled)
    let dustProtectionVM = SettingsCellViewModel(type: dustCellType, command: openURLCommand(for: dustCellType))
    return SettingsSectionViewModel(headerViewModel: SettingsHeaderFooterViewModel(title: "WALLET", command: nil),
                                    cellViewModels: [recoveryWordsVM, dustProtectionVM],
                                    footerViewModel: nil)
  }

  private func updateUIForMode() {
    settingsTitleLabel.text = mode.rawValue.uppercased()
    deleteWalletButton.isHidden = (mode != .settings)

    switch mode {
    case .settings:
      sendDebuggingInfoButton.isHidden = true
      resyncBlockchainButton.isHidden = false
    case .support:
      sendDebuggingInfoButton.isHidden = false
      resyncBlockchainButton.isHidden = true
    }
  }

  @IBAction func closeButtonWasTouched() {
    coordinationDelegate?.viewControllerDidSelectClose(self)
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
      guard let url = type.url else { return }
      localSelf.coordinationDelegate?.viewControllerDidRequestOpenURL(localSelf, url: url)
    })
  }

}
