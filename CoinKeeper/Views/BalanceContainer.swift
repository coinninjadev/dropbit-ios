//
//  BalanceContainer.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PromiseKit

protocol BalanceContainerDelegate: AnyObject {
  func containerDidTapLeftButton(in viewController: UIViewController)
  func containerDidTapDropBitMe(in viewController: UIViewController)
  func didTapRightBalanceView(in viewController: UIViewController)
  func didTapChartsButton()
  func isSyncCurrentlyRunning() -> Bool
  func selectedCurrency() -> SelectedCurrency
  func selectedWalletTransactionType() -> WalletTransactionType
  func dropBitMeAvatar() -> Promise<UIImage>
}

struct BalanceContainerDataSource {
  let leftButtonType: BalanceContainerLeftButtonType
  let onChainConverter: CurrencyConverter
  let lightningConverter: CurrencyConverter
  let primaryCurrency: CurrencyCode
}

enum BalanceContainerLeftButtonType {
  case menu
  case back

  var image: UIImage? {
    switch self {
    case .back: return UIImage(named: "back")
    case .menu: return UIImage(named: "menuButton")
    }
  }

  var badgeCriteria: BadgeInfo {
    switch self {
    case .back: return [:]
    case .menu: return [
      .unverifiedPhone: .actionNeeded,
      .transactionUpdates: .unseen,
      .wordsNotBackedUp: .actionNeeded
      ]
    }
  }
}

 class BalanceContainer: UIView, AccessibleViewSettable {

  weak var delegate: BalanceContainerDelegate?

  @IBOutlet var leftButton: BalanceContainerLeftButton!
  @IBOutlet var primarySecondaryBalanceContainer: PrimarySecondaryBalanceContainer!
  @IBOutlet var dropBitMeButton: UIButton!
  @IBOutlet var balanceView: UIView!
  @IBOutlet var rightBalanceContainerView: UIView!
  @IBOutlet var chartButton: UIButton!

  var startSyncNotificationToken: NotificationToken?
  var finishSyncNotificationToken: NotificationToken?
  var updateAvatarNotificationToken: NotificationToken?

  @IBAction func didTapLeftButton(_ sender: Any) {
    guard let delegate = delegate, let parent = parentViewController else { return }
    delegate.containerDidTapLeftButton(in: parent)
  }

  @IBAction func didTapDropBitMe(_ button: UIButton) {
    guard let delegate = delegate, let parent = parentViewController else { return }
    delegate.containerDidTapDropBitMe(in: parent)
  }

  @IBAction func didTapChartsButton() {
    guard let delegate = delegate else { return }
    delegate.didTapChartsButton()
  }

  @objc func didTapRightBalanceView() {
    guard let delegate = delegate, let parent = parentViewController else { return }
    delegate.didTapRightBalanceView(in: parent)
  }

  func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.balanceView, .walletOverview(.balanceView))
    ]
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  private func initialize() {
    backgroundColor = .clear
    xibSetup()
    dropBitMeButton.setImage(nil, for: .normal)
    leftButton.badgeDisplayCriteria = BalanceContainerLeftButtonType.menu.badgeCriteria
    subscribeToNotifications()
    setAccessibilityIdentifiers()
    rightBalanceContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapRightBalanceView)))
  }

  func update(with dataSource: BalanceContainerDataSource) {
    guard let delegate = delegate else { return }
    leftButton.setImage(dataSource.leftButtonType.image, for: .normal)
    leftButton.badgeDisplayCriteria = dataSource.leftButtonType.badgeCriteria

    updateAvatar()

    let converter = delegate.selectedWalletTransactionType() == .lightning ?
      dataSource.lightningConverter : dataSource.onChainConverter
    let primaryCurrency = dataSource.primaryCurrency
    let secondaryCurrency = converter.otherCurrency(forCurrency: primaryCurrency)
    let primaryAmount = converter.amount(forCurrency: primaryCurrency)
    let secondaryAmount = converter.amount(forCurrency: secondaryCurrency)
    primarySecondaryBalanceContainer.set(primaryAmount: primaryAmount, currency: primaryCurrency)
    primarySecondaryBalanceContainer.set(secondaryAmount: secondaryAmount, currency: secondaryCurrency)

    if delegate.isSyncCurrentlyRunning() {
      primarySecondaryBalanceContainer.isSyncing = false
    }
  }

  func toggleChartAndBalance() {
    rightBalanceContainerView.isHidden = chartButton.isHidden
    chartButton.isHidden = !chartButton.isHidden
  }

  private func selectedCurrency() -> SelectedCurrency {
    return delegate?.selectedCurrency() ?? .fiat
  }

  private func subscribeToNotifications() {
    subscribeToSyncNotifications()

    updateAvatarNotificationToken = CKNotificationCenter.subscribe(key: .didUpdateAvatar, object: nil, queue: nil) { [weak self] (_) in
      self?.updateAvatar()
    }
  }

  private func updateAvatar() {
    delegate?.dropBitMeAvatar()
      .done { (image: UIImage) in
        self.dropBitMeButton.setImage(image, for: .normal)
        let imageView = self.dropBitMeButton.imageView
        let radius = (imageView?.frame.width ?? 0) / 2.0
        imageView?.applyCornerRadius(radius)
      }.cauterize()
  }

}

extension BalanceContainer: SyncSubscribeable {

  func handleStartSync() {
    primarySecondaryBalanceContainer.isSyncing = true
  }

  func handleFinishSync() {
    primarySecondaryBalanceContainer.isSyncing = false
  }

}
