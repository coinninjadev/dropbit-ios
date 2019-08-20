//
//  PrimarySecondaryBalanceContainer.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/25/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol CurrencyPairDisplayable { }

extension CurrencyPairDisplayable {

  func attributedString(for amount: NSDecimalNumber?, currency: CurrencyCode) -> NSAttributedString {
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
    case .USD:  return NSAttributedString(string: currency.symbol + amountString)
    }
  }

  func attributedString(forSats sats: Int, size: CGFloat) -> NSAttributedString {
    let text = CKNumberFormatter.string(forSats: sats)
    return NSMutableAttributedString.medium(text, size: size, color: .bitcoinOrange)
  }

}

class PrimarySecondaryBalanceContainer: UIView, CurrencyPairDisplayable {

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

  func set(primaryAmount amount: NSDecimalNumber?, currency: CurrencyCode) {
    primaryBalanceLabel.attributedText = attributedString(for: amount, currency: currency)
    setupLabelColors(for: currency)
  }

  func set(secondaryAmount amount: NSDecimalNumber?, currency: CurrencyCode) {
    secondaryBalanceLabel.attributedText = attributedString(for: amount, currency: currency)
  }

  private func setupStyle() {
    switch style {
    case .medium:
      primaryBalanceLabel.font = .medium(19)
    case .large:
      primaryBalanceLabel.font = .regular(38)
    }
  }

  private func setupLabelColors(for primaryCurrency: CurrencyCode) {
    var primaryColor: UIColor, secondaryColor: UIColor

    switch primaryCurrency {
    case .BTC:
      primaryColor = .bitcoinOrange
      secondaryColor = .darkGray
    default:
      primaryColor = .darkGray
      secondaryColor = .bitcoinOrange
    }

    primaryBalanceLabel.textColor = primaryColor
    secondaryBalanceLabel.textColor = secondaryColor
  }

}
