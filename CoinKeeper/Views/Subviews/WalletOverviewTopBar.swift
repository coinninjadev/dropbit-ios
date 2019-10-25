//
//  WalletOverviewTopBar.swift
//  DropBit
//
//  Created by Ben Winters on 4/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PromiseKit

protocol WalletOverviewTopBarDelegate: DualBalanceViewDelegate {
  func containerDidTapLeftButton(in viewController: UIViewController)
  func containerDidTapDropBitMe(in viewController: UIViewController)
  func didTapChartsButton()
  func selectedCurrency() -> SelectedCurrency
  func dropBitMeAvatar() -> Promise<UIImage>
}

enum TopBarLeftButtonType {
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

 class WalletOverviewTopBar: UIView, AccessibleViewSettable {

  weak var delegate: WalletOverviewTopBarDelegate?

  @IBOutlet var leftButton: BalanceContainerLeftButton!
  @IBOutlet var balanceView: DualBalanceView!
  @IBOutlet var dropBitMeButton: UIButton!
  @IBOutlet var rightBalanceContainerView: UIView!
  @IBOutlet var chartButton: UIButton!

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
    leftButton.badgeDisplayCriteria = TopBarLeftButtonType.menu.badgeCriteria
    subscribeToNotifications()
    setAccessibilityIdentifiers()
  }

  func update(with labels: DualAmountLabels) {
    guard let delegate = delegate else { return }
    leftButton.configure(with: .menu)

    updateAvatar()
    self.balanceView.updateLabels(with: labels, selectedCurrency: delegate.selectedCurrency())
  }

  func toggleChartAndBalance() {
    rightBalanceContainerView.isHidden = chartButton.isHidden
    chartButton.isHidden = !chartButton.isHidden
  }

  private func selectedCurrency() -> SelectedCurrency {
    return delegate?.selectedCurrency() ?? .fiat
  }

  private func subscribeToNotifications() {
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
