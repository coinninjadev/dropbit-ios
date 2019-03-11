//
//  CalculatorCurrencyToggle.swift
//  CoinKeeper
//
//  Created by Ben Winters on 4/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol CalculatorCurrencyToggleDelegate: class {
  func didTapLeftCurrencyButton()
  func didTapRightCurrencyButton()
}

struct CalculatorCurrencyToggleConfig {
  var leftButtonTitle: String
  var rightButtonTitle: String
  var selectedSegment: CalculatorCurrencyToggleSegment
}

enum CalculatorCurrencyToggleSegment {
  case left, right
}

/**
 Holds two instances of CalculatorCurrencyButton and manages their titles and initial selection.
 */
@IBDesignable class CalculatorCurrencyToggle: UIView {

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
  }

  weak var delegate: CalculatorCurrencyToggleDelegate!

  @IBOutlet var leftButton: CalculatorCurrencyButton!
  @IBOutlet var rightButton: CalculatorCurrencyButton!

  @IBAction func didTapLeftButton(_ sender: Any) {
    delegate?.didTapLeftCurrencyButton()
  }

  @IBAction func didTapRightButton(_ sender: Any) {
    delegate?.didTapRightCurrencyButton()
  }

  func update(with config: CalculatorCurrencyToggleConfig) {
    leftButton.setTitle(config.leftButtonTitle, for: .normal)
    rightButton.setTitle(config.rightButtonTitle, for: .normal)
    leftButton.setTitle(config.leftButtonTitle, for: .selected)
    rightButton.setTitle(config.rightButtonTitle, for: .selected)

    leftButton.isSelected = config.selectedSegment == .left
    rightButton.isSelected = config.selectedSegment == .right
  }

}
