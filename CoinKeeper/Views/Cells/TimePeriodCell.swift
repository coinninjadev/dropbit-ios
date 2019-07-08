//
//  TimePeriodCell.swift
//  DropBit
//
//  Created by Mitchell Malleo on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol TimePeriodCellDelegate: class {
  func timePeriodWasSelected(_ period: TimePeriodCell.Period)
}

class TimePeriodCell: UITableViewCell {
  enum Period {
    case daily
    case monthly
    case alltime
  }

  @IBOutlet var monthlyButton: TimePeriodButton!
  @IBOutlet var allTimeButton: TimePeriodButton!

  var delegate: TimePeriodCellDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    monthlyButton.selected()
    allTimeButton.unselected()
    backgroundColor = .lightGrayBackground
  }

  @IBAction func timePeriodButtonWasSelected(_ button: UIButton!) {
    if button == monthlyButton {
      monthlyButton.selected()
      allTimeButton.unselected()
      delegate?.timePeriodWasSelected(.monthly)
    } else if button == allTimeButton {
      monthlyButton.unselected()
      allTimeButton.selected()
      delegate?.timePeriodWasSelected(.alltime)
    }
  }
}
