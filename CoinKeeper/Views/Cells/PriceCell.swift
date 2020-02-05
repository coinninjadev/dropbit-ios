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

  var movement: (gross: Double, percentage: Double)? {
    didSet {
      guard let movement = movement, movement.gross != 0, movement.percentage != 0 else { return }
      let grossNumber = NSDecimalNumber(value: movement.gross)
      let percentageNumber = NSNumber(value: movement.percentage)
      let amountString = FiatFormatter(currency: .USD, withSymbol: true).string(fromDecimal: grossNumber) ?? ""
      let percentageString = "(\(NumberFormatter.percentageFormatter.string(from: percentageNumber) ?? "")%)"
      let displayString: String =  amountString + " " + percentageString

      if movement.gross > 0 {
        movementLabel.textColor = .successGreen
      } else {
        movementLabel.textColor = .invalid
      }

      movementLabel.text = displayString
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .lightGrayBackground
    isUserInteractionEnabled = false
    selectionStyle = .none
  }
}
