//
//  WalletBalanceView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol WalletBalanceViewDelegate: class {
  func isSyncCurrentlyRunning() -> Bool
  func getCurrentWalletTransactionType() -> WalletTransactionType
  func transferButtonWasTouched()
  func swapPrimaryCurrency()
}

struct WalletBalanceDataSource {
  let onChainConverter: CurrencyConverter
  let lightningConverter: CurrencyConverter
  let primaryCurrency: CurrencyCode
}

class WalletBalanceView: UIView {
  @IBOutlet var reloadWalletButton: UIButton!
  @IBOutlet var primarySecondaryBalanceContainer: PrimarySecondaryBalanceContainer!

  weak var delegate: WalletBalanceViewDelegate?

  private var currentDataSource: WalletBalanceDataSource?

  lazy private var recognizer = UITapGestureRecognizer(target: self, action: #selector(balanceContainerWasTouched))

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .lightGrayBackground
    primarySecondaryBalanceContainer.style = .large
    primarySecondaryBalanceContainer.isSyncing = false

    reloadWalletButton.layer.shadowRadius = 1.0
    reloadWalletButton.layer.shadowOpacity = 0.3
    reloadWalletButton.layer.shadowColor = UIColor.black.cgColor
    reloadWalletButton.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
    reloadWalletButton.applyCornerRadius(15)
    reloadWalletButton.layer.masksToBounds = false
    primarySecondaryBalanceContainer.addGestureRecognizer(recognizer)
  }

  func refresh() {
    guard let dataSource = currentDataSource, let delegate = delegate else { return }
    update(with: dataSource, walletTransactionType: delegate.getCurrentWalletTransactionType())
  }

  func update(with dataSource: WalletBalanceDataSource, walletTransactionType: WalletTransactionType) {
    currentDataSource = dataSource
    guard let transactionType = delegate?.getCurrentWalletTransactionType() else { return }
    let converter: CurrencyConverter = transactionType == .lightning ? dataSource.lightningConverter : dataSource.onChainConverter

    let primaryCurrency = dataSource.primaryCurrency, primaryAmount = converter.amount(forCurrency: primaryCurrency)
    let secondaryCurrency = converter.otherCurrency(forCurrency: primaryCurrency)
    let secondaryAmount = converter.amount(forCurrency: secondaryCurrency)
    primarySecondaryBalanceContainer.set(primaryAmount: primaryAmount, currency: primaryCurrency, walletTransactionType: walletTransactionType)
    primarySecondaryBalanceContainer.set(secondaryAmount: secondaryAmount, currency: secondaryCurrency, walletTransactionType: walletTransactionType)

    if let syncRunning = delegate?.isSyncCurrentlyRunning(), syncRunning == false {
      primarySecondaryBalanceContainer.isSyncing = false
    }
  }

  @IBAction func transferButtonWasTouched() {
    delegate?.transferButtonWasTouched()
  }

  @objc func balanceContainerWasTouched() {
    switch recognizer.state {
    case .ended:
      delegate?.swapPrimaryCurrency()
    default:
      break
    }
  }
}
