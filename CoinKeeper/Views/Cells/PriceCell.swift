//
//  PriceCell.swift
//  DropBit
//
//  Created by Mitchell Malleo on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class PriceCell: UITableViewCell {

  @IBOutlet var priceLabel: UILabel! {
    didSet {
      priceLabel.font = .light(44)
      priceLabel.textColor = .darkBlueText
    }
  }

  @IBOutlet var movementLabel: UILabel! {
    didSet {
      movementLabel.font = .regular(14)
    }
  }

  private lazy var formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    formatter.locale = Locale.current
    formatter.usesGroupingSeparator = true
    formatter.numberStyle = .currency
    return formatter
  }()

  var movement: (usd: Double, percent: Double)? {
    didSet {
      guard let movement = movement, movement.usd != 0, movement.percent != 0 else { return }
      let displayString: String
      if movement.percent < 0 {
        displayString = formatter.string(from: (movement.usd as? NSNumber ?? 0.0)) ?? ""
        movementLabel.textColor = .mango
      } else {
        displayString = "+" + (formatter.string(from: (movement.usd as? NSNumber ?? 0.0)) ?? "")
        movementLabel.textColor = .successGreen
      }

      movementLabel.text = displayString
    }
  }

  @IBOutlet var candleSelectionLabel: UILabel! {
    didSet {
      candleSelectionLabel.font = .regular(14)
      candleSelectionLabel.textColor = .darkGrayText
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .lightGrayBackground
  }
}
