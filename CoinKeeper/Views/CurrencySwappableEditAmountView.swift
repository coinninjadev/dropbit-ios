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

  override func awakeFromNib() {
    super.awakeFromNib()

    secondaryAmountLabel.textColor = .darkGrayText
    secondaryAmountLabel.font = .regular(17)
  }

  func configure(withLabels labels: DualAmountLabels,
                 delegate: CurrencySwappableEditAmountViewDelegate) {
    self.update(labels)
    self.delegate = delegate
  }

  func update(_ labels: DualAmountLabels) {
    primaryAmountTextField.text = labels.primary
    secondaryAmountLabel.text = labels.secondary
  }

}
