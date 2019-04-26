//
//  BalanceContainer.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/9/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol BalanceContainerDelegate: AnyObject {
  func containerDidTapLeftButton(in viewController: UIViewController)
  func containerDidTapDropBitMe(in viewController: UIViewController)
  func containerDidTapBalances(in viewController: UIViewController)
  func containerDidLongPressBalances(in viewController: UIViewController)
  func isSyncCurrentlyRunning() -> Bool
  func selectedCurrency() -> SelectedCurrency
}

struct BalanceContainerDataSource {
  let leftButtonType: BalanceContainerLeftButtonType
  let converter: CurrencyConverter
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

@IBDesignable class BalanceContainer: UIView, AccessibleViewSettable {

  weak var delegate: BalanceContainerDelegate?

  @IBOutlet var leftButton: BalanceContainerLeftButton!
  @IBOutlet var dropBitMeButton: UIButton!
  @IBOutlet var primaryAmountLabel: BalancePrimaryAmountLabel!
  @IBOutlet var secondaryAmountLabel: BalanceSecondaryAmountLabel!
  @IBOutlet var balanceView: UIView!
  @IBOutlet var balancesTapGestureRecognizer: UITapGestureRecognizer!
  @IBOutlet var balancesLongPressRecognizer: UILongPressGestureRecognizer!
  @IBOutlet var syncActivityIndicator: UIImageView!

  var startSyncNotificationToken: NotificationToken?
  var finishSyncNotificationToken: NotificationToken?

  @IBAction func didTapLeftButton(_ sender: Any) {
    guard let delegate = delegate, let parent = parentViewController else { return }
    delegate.containerDidTapLeftButton(in: parent)
  }

  @IBAction func didTapDropBitMe(_ button: UIButton) {
    guard let delegate = delegate, let parent = parentViewController else { return }
    delegate.containerDidTapDropBitMe(in: parent)
  }

  @IBAction func didTapBalances(_ sender: UITapGestureRecognizer) {
    guard let delegate = delegate, let parent = parentViewController else { return }
    delegate.containerDidTapBalances(in: parent)
  }

  @IBAction func didLongPressBalances(_ sender: UILongPressGestureRecognizer) {
    guard let delegate = delegate, let parent = parentViewController else { return }
    delegate.containerDidLongPressBalances(in: parent)
  }

  func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.balanceView, .transactionHistory(.balanceView))
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
    leftButton.badgeDisplayCriteria = BalanceContainerLeftButtonType.menu.badgeCriteria
    guard let imageData = UIImage.data(asset: "syncing") else { return }
    syncActivityIndicator.prepareForAnimation(withGIFData: imageData)
    syncActivityIndicator.startAnimatingGIF()
    subscribeToSyncNotifications()
    setAccessibilityIdentifiers()
  }

  func update(with dataSource: BalanceContainerDataSource) {
    leftButton.setImage(dataSource.leftButtonType.image, for: .normal)
    leftButton.badgeDisplayCriteria = dataSource.leftButtonType.badgeCriteria

    let primaryCurrency = dataSource.primaryCurrency
    let secondaryCurrency = dataSource.converter.otherCurrency(forCurrency: primaryCurrency) ?? .USD
    let primaryAmount = dataSource.converter.amount(forCurrency: primaryCurrency)
    let secondaryAmount = dataSource.converter.amount(forCurrency: secondaryCurrency)
    primaryAmountLabel.attributedText = label(for: primaryAmount, currency: primaryCurrency)
    secondaryAmountLabel.attributedText = label(for: secondaryAmount, currency: secondaryCurrency)

    if let syncRunning = delegate?.isSyncCurrentlyRunning(), syncRunning == false {
      setSyncVisibility(hidden: true)
    }
  }

  private func selectedCurrency() -> SelectedCurrency {
    return delegate?.selectedCurrency() ?? .fiat
  }

  private func subscribeToSyncNotifications() {
    startSyncNotificationToken = CKNotificationCenter.subscribe(key: .didStartSync, object: nil, queue: nil) { [weak self] (_) in
      self?.handleStartSync()
    }

    finishSyncNotificationToken = CKNotificationCenter.subscribe(key: .didFinishSync, object: nil, queue: nil) { [weak self] (_) in
      self?.handleFinishSync()
    }
  }

  private func handleStartSync() {
    setSyncVisibility(hidden: false)
  }

  private func handleFinishSync() {
    setSyncVisibility(hidden: true)
  }

  private func setSyncVisibility(hidden: Bool) {
    syncActivityIndicator.isHidden = hidden
  }

  private func label(for amount: NSDecimalNumber?, currency: CurrencyCode) -> NSAttributedString {
    guard let amount = amount else { return NSAttributedString(string: "–") }

    let minFractionalDigits: Int = currency.shouldRoundTrailingZeroes ? 0 : currency.decimalPlaces
    let maxfractionalDigits: Int = currency.decimalPlaces

    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = minFractionalDigits
    formatter.maximumFractionDigits = maxfractionalDigits

    let amountString = formatter.string(from: amount) ?? "–"

    switch currency {
    case .BTC:
      if let symbol = currency.attributedStringSymbol() {
        return symbol + NSAttributedString(string: amountString)
      } else {
        return NSAttributedString(string: amountString)
      }
    case .USD:	return NSAttributedString(string: currency.symbol + amountString)
    }
  }

}
