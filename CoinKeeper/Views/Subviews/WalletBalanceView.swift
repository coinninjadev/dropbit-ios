//
//  WalletBalanceView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol WalletBalanceViewDelegate: DualBalanceViewDelegate {
  func currentLockStatus() -> LockStatus
  func transferButtonWasTouched()
  func swapSelectedCurrency()
}

class WalletBalanceView: UIView {
  @IBOutlet var reloadWalletButton: UIButton!
  @IBOutlet var balanceView: DualBalanceView!

  weak var delegate: WalletBalanceViewDelegate?

  lazy private var recognizer = UITapGestureRecognizer(target: self, action: #selector(balanceViewWasTouched))

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
    balanceView.style = .large
    balanceView.isSyncing = false

    reloadWalletButton.layer.shadowRadius = 1.0
    reloadWalletButton.layer.shadowOpacity = 0.3
    reloadWalletButton.layer.shadowColor = UIColor.black.cgColor
    reloadWalletButton.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
    reloadWalletButton.applyCornerRadius(15)
    reloadWalletButton.layer.masksToBounds = false
    balanceView.addGestureRecognizer(recognizer)
  }

  func update(with labels: DualAmountLabels) {
    guard let delegate = delegate else { return }
    balanceView.updateLabels(with: labels, selectedCurrency: delegate.selectedCurrency())
    balanceView.isSyncing = delegate.isSyncCurrentlyRunning()
  }

  @IBAction func transferButtonWasTouched() {
    guard let delegate = delegate, delegate.currentLockStatus() != .locked else { return }
    delegate.transferButtonWasTouched()
  }

  @objc func balanceViewWasTouched() {
    switch recognizer.state {
    case .ended:
      delegate?.swapSelectedCurrency()
    default:
      break
    }
  }
}
