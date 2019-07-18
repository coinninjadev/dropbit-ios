//
//  CurrencySwappableEditAmountView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/11/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol CurrencySwappableEditAmountViewDelegate: AnyObject {
  func swapViewDidSwap(_ swapView: CurrencySwappableEditAmountView)
}

struct DualAmountLabels {
  let primary: NSAttributedString?
  let secondary: NSAttributedString?
}

class CurrencySwappableEditAmountView: UIView {

  weak var delegate: CurrencySwappableEditAmountViewDelegate!

  @IBOutlet var primaryAmountTextField: LimitEditTextField!
  @IBOutlet var secondaryAmountLabel: UILabel!
  @IBOutlet var swapButton: UIButton!

  @IBAction func performSwap(_ sender: Any) {
    delegate.swapViewDidSwap(self)
  }

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

    backgroundColor = .clear

    secondaryAmountLabel.textColor = .darkGrayText
    secondaryAmountLabel.font = .regular(17)
  }

  func configure(withLabels labels: DualAmountLabels,
                 delegate: CurrencySwappableEditAmountViewDelegate) {
    update(with: labels)
    self.delegate = delegate
  }

  func update(with labels: DualAmountLabels) {
    primaryAmountTextField.attributedText = labels.primary
    secondaryAmountLabel.attributedText = labels.secondary
  }

}
