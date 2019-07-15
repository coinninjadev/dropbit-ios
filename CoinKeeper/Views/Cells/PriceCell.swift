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

  private lazy var percentageFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    formatter.locale = Locale.current
    formatter.usesGroupingSeparator = true
    return formatter
  }()

  var movement: (gross: Double, percentage: Double)? {
    didSet {
      guard let movement = movement, movement.gross != 0, movement.percentage != 0 else { return }
      let displayString: String = (CKNumberFormatter.currencyFormatter.string(from: (movement.gross as NSNumber)) ?? "") + " " +
        "(\(percentageFormatter.string(from: (movement.percentage as NSNumber)) ?? "")%)"

      if movement.gross > 0 {
        movementLabel.textColor = .successGreen
      } else {
        movementLabel.textColor = .mango
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
