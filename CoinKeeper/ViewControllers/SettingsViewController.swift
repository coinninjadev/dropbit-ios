//
//  SettingsViewController.swift
//  DropBit
//
//  Created by Mitchell on 5/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol SettingsViewControllerDelegate: ViewControllerDismissable, ViewControllerURLDelegate {

  var persistenceManager: PersistenceManagerType { get }
  func verifyIfWordsAreBackedUp() -> Bool
  func dustProtectionIsEnabled() -> Bool
  func yearlyHighPushNotificationIsSubscribed() -> Bool

  func viewControllerDidRequestDeleteWallet(_ viewController: UIViewController,
                                            completion: @escaping CKCompletion)
  func viewControllerDidConfirmDeleteWallet(_ viewController: UIViewController)
  func viewControllerDidSelectOpenSourceLicenses(_ viewController: UIViewController)
  func viewControllerDidSelectRecoveryWords(_ viewController: UIViewController)
  func viewControllerDidSelectReviewLegacyWords(_ viewController: UIViewController)
  func viewControllerDidSelectAdjustableFees(_ viewController: UIViewController)
  func viewControllerResyncBlockchain(_ viewController: UIViewController)
  func viewController(_ viewController: UIViewController, didEnableDustProtection didEnable: Bool)
  func viewController(_ viewController: UIViewController, didEnableYearlyHighNotification didEnable: Bool, completion: @escaping CKCompletion)
}

class SettingsViewController: BaseViewController, StoryboardInitializable {

  var viewModel: SettingsViewModel!

  private(set) weak var delegate: SettingsViewControllerDelegate!

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
  @IBOutlet var resyncBlockchainButton: PrimaryActionButton! {
    didSet {
      resyncBlockchainButton.setTitle("Sync Blockchain", for: .normal)
    }
  }

  @IBAction func deleteWallet(_ sender: Any) {
    delegate.viewControllerDidRequestDeleteWallet(self, completion: {
      self.delegate.viewControllerDidConfirmDeleteWallet(self)
      self.delegate.viewControllerDidSelectClose(self)
    })
  }

  @IBAction func resyncBlockchain(_ sender: Any) {
    delegate.viewControllerResyncBlockchain(self)
  }

  @objc func close() {
    delegate.viewControllerDidSelectClose(self)
  }

  static func newInstance(with delegate: SettingsViewControllerDelegate) -> SettingsViewController {
    let controller = SettingsViewController.makeFromStoryboard()
    controller.delegate = delegate
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
    settingsTableView.registerNib(cellType: SettingsWithInfoCell.self)
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
    return delegate.verifyIfWordsAreBackedUp()
  }

  private func createViewModel() -> SettingsViewModel {
    let sectionViewModels: [SettingsSectionViewModel]
    let walletSection = walletSectionViewModel()
    let licensesType = SettingsCellType.licenses { [weak self] in
      guard let localSelf = self else { return }
      localSelf.delegate.viewControllerDidSelectOpenSourceLicenses(localSelf)
    }
    let licensesSection = SettingsSectionViewModel(
      headerViewModel: SettingsHeaderFooterViewModel(title: "LICENSES"),
      cellViewModels: [SettingsCellViewModel(type: licensesType)])
    sectionViewModels = [walletSection, licensesSection]

    return SettingsViewModel(sectionViewModels: sectionViewModels)
  }

  private func walletSectionViewModel() -> SettingsSectionViewModel {
    // legacy words, if exists
    let legacyWords = delegate.persistenceManager.keychainManager.retrieveValue(for: .walletWords)
    var legacyWordsVM: SettingsCellViewModel?
    if legacyWords != nil {
      let legacyWordsCellType = SettingsCellType.legacyWords(action: { [weak self] in
        guard let localSelf = self else { return }
        localSelf.delegate.viewControllerDidSelectReviewLegacyWords(localSelf)
        }, infoAction: { [weak self] (type: SettingsCellType) -> Void in
          guard let localSelf = self, let url = type.url else { return }
          localSelf.delegate.viewController(localSelf, didRequestOpenURL: url)
      })
      legacyWordsVM = SettingsCellViewModel(type: legacyWordsCellType)
    }

    // recovery words
    let recoveryWordsCellType = SettingsCellType.recoveryWords(isWalletBackedUp()) { [weak self] in
      guard let localSelf = self else { return }
      localSelf.delegate.viewControllerDidSelectRecoveryWords(localSelf)
    }
    let recoveryWordsVM = SettingsCellViewModel(type: recoveryWordsCellType)

    // dust protection
    let dustProtectionEnabled = delegate.dustProtectionIsEnabled()
    let dustCellType = SettingsCellType.dustProtection(
      enabled: dustProtectionEnabled,
      infoAction: { [weak self] (type: SettingsCellType) in
        guard let localSelf = self, let url = type.url else { return }
        localSelf.delegate.viewController(localSelf, didRequestOpenURL: url)
      },
      onChange: { [weak self] (didEnable: Bool) in
        guard let localSelf = self else { return }
        localSelf.delegate.viewController(localSelf, didEnableDustProtection: didEnable)
      }
    )
    let dustProtectionVM = SettingsCellViewModel(type: dustCellType)

    // yearly high push notification
    let isYearlyHighPushEnabled = delegate.yearlyHighPushNotificationIsSubscribed()
    let yearlyHighCellType = SettingsCellType.yearlyHighPushNotification(enabled: isYearlyHighPushEnabled) { [weak self] (didEnable: Bool) in
      guard let localSelf = self else { return }
      localSelf.delegate.viewController(
        localSelf,
        didEnableYearlyHighNotification: didEnable,
        completion: { [weak self] in
          guard let localSelf = self else { return }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            localSelf.viewModel = localSelf.createViewModel()
            localSelf.settingsTableView.reloadData()
          }
        }
      )
    }
    let yearlyHighVM = SettingsCellViewModel(type: yearlyHighCellType)

    // adjustable fees
    let adjustableFeesAction: BasicAction = { [weak self] in
      guard let localSelf = self else { return }
      localSelf.delegate.viewControllerDidSelectAdjustableFees(localSelf)
    }
    let adjustableFeesVM = SettingsCellViewModel(type: .adjustableFees(action: adjustableFeesAction))

    // regtest vs mainnet
    var regtestVM: SettingsCellViewModel?
    #if DEBUG
    let useRegtest = CKUserDefaults().useRegtest
    let regtestCellType = SettingsCellType.regtest(enabled: useRegtest) { (didEnable: Bool) in
      CKUserDefaults().useRegtest = didEnable
    }
    regtestVM = SettingsCellViewModel(type: regtestCellType)
    #endif

    // form array of cell view models
    let viewModels = [
      legacyWordsVM,
      recoveryWordsVM,
      dustProtectionVM,
      yearlyHighVM,
      adjustableFeesVM,
      regtestVM
      ]
      .compactMap { $0 }

    // return section view model
    return SettingsSectionViewModel(
      headerViewModel: SettingsHeaderFooterViewModel(title: "WALLET"),
      cellViewModels: viewModels)
  }

}
