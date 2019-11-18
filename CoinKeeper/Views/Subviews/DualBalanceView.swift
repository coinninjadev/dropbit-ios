//
//  DualBalanceView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol DualBalanceViewDelegate: AnyObject {
  func isSyncCurrentlyRunning() -> Bool
  func selectedCurrency() -> SelectedCurrency
}

class DualBalanceView: UIView {

  @IBOutlet var primaryBalanceLabel: BalancePrimaryAmountLabel!
  @IBOutlet var secondaryBalanceLabel: BalanceSecondaryAmountLabel!
  @IBOutlet var syncActivityIndicator: UIImageView!

  enum Style {
    case medium
    case large
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
  }

  var isSyncing: Bool = false {
    willSet {
      syncActivityIndicator.isHidden = !newValue
    }
  }

  var style: Style = .medium {
    didSet {
      setupStyle()
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    guard let imageData = UIImage.data(asset: "syncing") else { return }
    syncActivityIndicator.prepareForAnimation(withGIFData: imageData)
    syncActivityIndicator.startAnimatingGIF()
    backgroundColor = .lightGrayBackground
    secondaryBalanceLabel.textColor = .bitcoinOrange
  }

  func updateLabels(with labels: DualAmountLabels, selectedCurrency: SelectedCurrency) {
    primaryBalanceLabel.attributedText = labels.primary
    secondaryBalanceLabel.attributedText = labels.secondary
    setupLabelColors(for: selectedCurrency)
  }

  private func setupStyle() {
    switch style {
    case .medium:
      primaryBalanceLabel.font = .medium(19)
    case .large:
      primaryBalanceLabel.font = .regular(38)
    }
  }

  private func setupLabelColors(for selectedCurrency: SelectedCurrency) {
    var primaryColor: UIColor, secondaryColor: UIColor

    switch selectedCurrency {
    case .BTC:
      primaryColor = .bitcoinOrange
      secondaryColor = .darkGray
    case .fiat:
      primaryColor = .darkGray
      secondaryColor = .bitcoinOrange
    }

    primaryBalanceLabel.textColor = primaryColor
    secondaryBalanceLabel.textColor = secondaryColor
  }

}
