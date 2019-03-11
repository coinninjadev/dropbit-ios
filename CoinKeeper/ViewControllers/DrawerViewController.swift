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
  func historyButtonWasTouched()
  func phoneButtonWasTouched()
  func spendButtonWasTouched()
  func supportButtonWasTouched()
  func badgingManager() -> BadgeManagerType
}

class DrawerViewController: BaseViewController, StoryboardInitializable {
  override var generalCoordinationDelegate: AnyObject? {
    didSet {
      drawerTableViewDDS?.currencyValueManager = coordinationDelegate
      drawerTableView?.reloadData() // rebuild header with price data; Note: drawerTableView may not yet exist
      coordinationDelegate?.viewControllerDidRequestBadgeUpdate(self)
      (coordinationDelegate?.badgingManager()).map(subscribeToBadgeNotifications)
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
    versionLabel.font = Theme.Font.settingsVersion.font
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
    let phoneOffset = ViewOffset(dx: 4, dy: -8)

    let backupWordsDrawerData: () -> DrawerData? = { [weak self] in
      guard let backedUp = self?.coordinationDelegate?.badgingManager().wordsBackedUp, backedUp == false else { return nil }
      return DrawerData(image: nil, title: "Back Up Wallet", kind: .backupWords)
    }

    let settingsData: [DrawerData] = [
      backupWordsDrawerData(),
      DrawerData(image: #imageLiteral(resourceName: "historyIcon"), title: "History", kind: .history, badgeCriteria: [.transactionUpdates: .unseen], badgeOffset: circularIconOffset),
      DrawerData(image: #imageLiteral(resourceName: "settingsIcon"), title: "Settings", kind: .settings, badgeCriteria: [.wordsNotBackedUp: .actionNeeded], badgeOffset: circularIconOffset),
      DrawerData(image: #imageLiteral(resourceName: "phoneDrawerIcon"), title: "Phone", kind: .phone, badgeCriteria: [.unverifiedPhone: .actionNeeded], badgeOffset: phoneOffset),
      DrawerData(image: #imageLiteral(resourceName: "bitcoinIcon"), title: "Spend", kind: .spend),
      DrawerData(image: #imageLiteral(resourceName: "supportIcon"), title: "Support", kind: .support)
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
    case .history:
      coordinationDelegate?.historyButtonWasTouched()
    case .phone:
      coordinationDelegate?.phoneButtonWasTouched()
    case .spend:
      coordinationDelegate?.spendButtonWasTouched()
    case .support:
      coordinationDelegate?.supportButtonWasTouched()
    }
  }
}

extension DrawerViewController: BadgeDisplayable {

  func didReceiveBadgeUpdate(badgeInfo: BadgeInfo) {
    drawerTableViewDDS?.latestBadgeInfo = badgeInfo
    configureDrawerData()
  }

}
