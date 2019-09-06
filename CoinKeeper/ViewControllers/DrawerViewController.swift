//
//  DrawerViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol DrawerViewControllerDelegate: CurrencyValueDataSourceType & BadgeUpdateDelegate {
  func backupWordsWasTouched()
  func settingsButtonWasTouched()
  func verifyButtonWasTouched()
  func spendButtonWasTouched()
  func supportButtonWasTouched()
  func getBitcoinButtonWasTouched()
  var badgeManager: BadgeManagerType { get }
}

class DrawerViewController: BaseViewController, StoryboardInitializable {

  fileprivate weak var delegate: DrawerViewControllerDelegate!

  var drawerTableViewDDS: DrawerTableViewDDS?

  var badgeNotificationToken: NotificationToken?

  private let versionKey: String = "CFBundleShortVersionString"

  // MARK: outlets
  @IBOutlet var drawerTableView: UITableView!
  @IBOutlet var versionLabel: UILabel!

  static func newInstance(delegate: DrawerViewControllerDelegate) -> DrawerViewController {
    let vc = DrawerViewController.makeFromStoryboard()
    vc.delegate = delegate
    vc.drawerTableViewDDS?.currencyValueManager = delegate
    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    versionLabel.textColor = UIColor.white
    versionLabel.font = .light(10)
    versionLabel.text = "Version \(Bundle.main.infoDictionary?[versionKey] ?? "Unknown")"

    drawerTableView.registerNib(cellType: DrawerCell.self)
    drawerTableView.registerNib(cellType: BackupWordsReminderDrawerCell.self)
    drawerTableView.registerHeaderFooter(headerFooterType: DrawerTableViewHeader.self)

    drawerTableView.reloadData() // rebuild header with price data
    delegate.viewControllerDidRequestBadgeUpdate(self)
    self.subscribeToBadgeNotifications(with: delegate.badgeManager)

    view.backgroundColor = .darkBlueBackground
    setupDataSource()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    configureDrawerData()
  }

  private func setupDataSource() {
    let settingsActionHandler: (DrawerData.Kind) -> Void = { [weak self] (kind) in
      self?.buttonWasTouched(for: kind)
    }

    drawerTableViewDDS = DrawerTableViewDDS(settingsActionHandler: settingsActionHandler)
    drawerTableView.delegate = drawerTableViewDDS
    drawerTableView.dataSource = drawerTableViewDDS
    drawerTableView.backgroundColor = .clear
    drawerTableView.showsVerticalScrollIndicator = false
    drawerTableView.separatorStyle = .none
    drawerTableView.alwaysBounceVertical = false
    drawerTableView.reloadData()
  }

  private func configureDrawerData() {
    let circularIconOffset = ViewOffset(dx: 7, dy: -2)

    let backupWordsDrawerData: () -> DrawerData? = { [weak self] in
      guard let backedUp = self?.delegate.badgeManager.wordsBackedUp, backedUp == false else { return nil }
      return DrawerData(image: nil, title: "Back Up Wallet", kind: .backupWords)
    }

    let getBitcoinImage = UIImage(imageLiteralResourceName: "drawerGetBitcoinIcon")
    let settingsImage = UIImage(imageLiteralResourceName: "drawerSettingsIcon")
    let verifyIcon = UIImage(imageLiteralResourceName: "drawerPhoneVerificationIcon")
    let spendIcon = UIImage(imageLiteralResourceName: "drawerSpendBitcoinIcon")
    let supportIcon = UIImage(imageLiteralResourceName: "drawerSupportIcon")

    let settingsCritera: BadgeInfo = [.wordsNotBackedUp: .actionNeeded]
    let verifyCriteria: BadgeInfo = [.unverifiedPhone: .actionNeeded]

    let settingsData: [DrawerData] = [
      backupWordsDrawerData(),
      DrawerData(image: getBitcoinImage, title: "Get Bitcoin", kind: .getBitcoin),
      DrawerData(image: settingsImage, title: "Settings", kind: .settings, badgeCriteria: settingsCritera, badgeOffset: circularIconOffset),
      DrawerData(image: verifyIcon, title: "Verify", kind: .verify, badgeCriteria: verifyCriteria, badgeOffset: circularIconOffset),
      DrawerData(image: spendIcon, title: "Spend", kind: .spend),
      DrawerData(image: supportIcon, title: "Support", kind: .support)
      ]
      .compactMap { $0 }

    drawerTableViewDDS?.settingsData = settingsData

    drawerTableView.reloadData()
  }

  private func buttonWasTouched(for kind: DrawerData.Kind) {
    switch kind {
    case .backupWords:
      delegate.backupWordsWasTouched()
    case .settings:
      delegate.settingsButtonWasTouched()
    case .verify:
      delegate.verifyButtonWasTouched()
    case .spend:
      delegate.spendButtonWasTouched()
    case .support:
      delegate.supportButtonWasTouched()
    case .getBitcoin:
      delegate.getBitcoinButtonWasTouched()
    }
  }
}

extension DrawerViewController: BadgeDisplayable {

  func didReceiveBadgeUpdate(badgeInfo: BadgeInfo) {
    drawerTableViewDDS?.latestBadgeInfo = badgeInfo
    configureDrawerData()
  }

}
