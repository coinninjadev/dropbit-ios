//
//  FeesView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol FeesViewDelegate: class {
  func tooltipButtonWasTouched()
}

class FeesView: UIView {

  @IBOutlet var topLabel: UILabel!
  @IBOutlet var topTitleLabel: UILabel!
  @IBOutlet var bottomTitleLabel: UILabel!
  @IBOutlet var bottomLabel: UILabel!
  @IBOutlet var tooltipButton: UIButton!

  weak var delegate: FeesViewDelegate?

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

    topLabel.font = .regular(13)
    topLabel.textColor = .darkGrayText

    topTitleLabel.font = .regular(13)
    topTitleLabel.textColor = .darkGrayText

    bottomTitleLabel.font = .regular(13)
    bottomTitleLabel.textColor = .darkGrayText

    bottomLabel.font = .regular(13)
    bottomLabel.textColor = .darkGrayText

    layer.cornerRadius = 15.0
    clipsToBounds = true
    backgroundColor = .extraLightGrayBackground
    layer.borderColor = UIColor.mediumGrayBorder.cgColor
    layer.borderWidth = 1.0
  }

  func setupFees(top topSats: Int, bottom bottomSats: Int) {
    let satsFormatter = SatsFormatter(), manager = ExchangeRateManager()
    let fiatFormatter = FiatFormatter(currency: .USD, withSymbol: true)
    let topFee = NSDecimalNumber(integerAmount: topSats, currency: .BTC)
    let bottomFee = NSDecimalNumber(integerAmount: bottomSats, currency: .BTC)
    let currencyConvterterTop = CurrencyConverter(fromBtcTo: .USD,
                                                  fromAmount: topFee,
                                                  rates: manager.exchangeRates)
    let currencyConvterterBottom = CurrencyConverter(fromBtcTo: .USD,
                                                     fromAmount: bottomFee,
                                                     rates: manager.exchangeRates)
    guard let topDecimal = currencyConvterterTop.amount(forCurrency: .USD),
    let bottomDecimal = currencyConvterterBottom.amount(forCurrency: .USD) else { return }
    topLabel.text = """
      \(satsFormatter.string(fromDecimal: topFee) ?? "") (\(fiatFormatter.string(fromDecimal: topDecimal) ?? ""))
      """.removingMultilineLineBreaks()
    bottomLabel.text = """
      \(satsFormatter.string(fromDecimal: bottomFee) ?? "") (\(fiatFormatter.string(fromDecimal: bottomDecimal) ?? ""))
      """.removingMultilineLineBreaks()
  }

  @IBAction func tooltipButtonWasTouched() {
    delegate?.tooltipButtonWasTouched()
  }

}
