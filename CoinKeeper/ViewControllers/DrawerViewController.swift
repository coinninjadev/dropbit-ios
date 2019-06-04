//
//  DrawerViewController.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 4/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol DrawerViewControllerDelegate: CurrencyValueDataSourceType & BadgeUpdateDelegate {
  func backupWordsWasTouched()
  func settingsButtonWasTouched()
  func phoneButtonWasTouched()
  func spendButtonWasTouched()
  func supportButtonWasTouched()
  func getBitcoinButtonWasTouched()
  var badgeManager: BadgeManagerType { get }
}

class DrawerViewController: BaseViewController, StoryboardInitializable {
  override var generalCoordinationDelegate: AnyObject? {
    didSet {
      drawerTableViewDDS?.currencyValueManager = coordinationDelegate
      drawerTableView?.reloadData() // rebuild header with price data; Note: drawerTableView may not yet exist
      coordinationDelegate?.viewControllerDidRequestBadgeUpdate(self)
      (coordinationDelegate?.badgeManager).map(subscribeToBadgeNotifications)
      self.configureDrawerData()
    }
  }
  var coordinationDelegate: DrawerViewControllerDelegate? {
    return generalCoordinationDelegate as? DrawerViewControllerDelegate
  }
  var drawerTableViewDDS: DrawerTableViewDDS?

  var badgeNotificationToken: NotificationToken?

  private let versionKey: String = "CFBundleShortVersionString"

  // MARK: outlets
  @IBOutlet var drawerTableView: UITableView!
  @IBOutlet var versionLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()

    versionLabel.textColor = UIColor.white
    versionLabel.font = CKFont.light(10)
    versionLabel.text = "Version \(Bundle.main.infoDictionary?[versionKey] ?? "Unknown")"

    drawerTableView.registerNib(cellType: DrawerCell.self)
    drawerTableView.registerNib(cellType: BackupWordsReminderDrawerCell.self)
    drawerTableView.registerHeaderFooter(headerFooterType: DrawerTableViewHeader.self)

    view.backgroundColor = Theme.Color.settingsDarkGray.color

    drawerTableViewDDS = DrawerTableViewDDS { [weak self] (kind) in
      self?.buttonWasTouched(for: kind)
    }
    drawerTableView.delegate = drawerTableViewDDS
    drawerTableView.dataSource = drawerTableViewDDS
    drawerTableView.backgroundColor = .clear
    drawerTableView.showsVerticalScrollIndicator = false
    drawerTableView.separatorStyle = .none
    drawerTableView.alwaysBounceVertical = false
    drawerTableView.reloadData()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    configureDrawerData()
  }

  private func configureDrawerData() {
    let circularIconOffset = ViewOffset(dx: 7, dy: -2)

    let backupWordsDrawerData: () -> DrawerData? = { [weak self] in
      guard let backedUp = self?.coordinationDelegate?.badgeManager.wordsBackedUp, backedUp == false else { return nil }
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
      DrawerData(image: verifyIcon, title: "Verify", kind: .phone, badgeCriteria: verifyCriteria, badgeOffset: circularIconOffset),
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
      coordinationDelegate?.backupWordsWasTouched()
    case .settings:
      coordinationDelegate?.settingsButtonWasTouched()
    case .phone:
      coordinationDelegate?.phoneButtonWasTouched()
    case .spend:
      coordinationDelegate?.spendButtonWasTouched()
    case .support:
      coordinationDelegate?.supportButtonWasTouched()
    case .getBitcoin:
      coordinationDelegate?.getBitcoinButtonWasTouched()
    }
  }
}

extension DrawerViewController: BadgeDisplayable {

  func didReceiveBadgeUpdate(badgeInfo: BadgeInfo) {
    drawerTableViewDDS?.latestBadgeInfo = badgeInfo
    configureDrawerData()
  }

}
