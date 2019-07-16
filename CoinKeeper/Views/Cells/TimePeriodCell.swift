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
    case week
    case monthly
    case yearly
    case alltime
  }

  @IBOutlet var monthlyButton: TimePeriodButton!
  @IBOutlet var dayButton: TimePeriodButton!
  @IBOutlet var weekButton: TimePeriodButton!
  @IBOutlet var yearButton: TimePeriodButton!
  @IBOutlet var allTimeButton: TimePeriodButton!

  private var buttons: [TimePeriodButton] = []

  weak var delegate: TimePeriodCellDelegate?

  override func awakeFromNib() {
    super.awakeFromNib()
    dayButton.selected()
    backgroundColor = .lightGrayBackground
    buttons = [monthlyButton, dayButton, weekButton, yearButton, allTimeButton]
    selectionStyle = .none
  }

  @IBAction func timePeriodButtonWasSelected(_ button: UIButton!) {
    guard let button = button as? TimePeriodButton else { return }
    var selectedButton: TimePeriodButton

    switch button {
    case monthlyButton:
      selectedButton = monthlyButton
      delegate?.timePeriodWasSelected(.monthly)
    case weekButton:
      selectedButton = weekButton
      delegate?.timePeriodWasSelected(.week)
    case yearButton:
      selectedButton = yearButton
      delegate?.timePeriodWasSelected(.yearly)
    case allTimeButton:
      selectedButton = allTimeButton
      delegate?.timePeriodWasSelected(.alltime)
    default:
      selectedButton = dayButton
      delegate?.timePeriodWasSelected(.daily)
    }

    for button in buttons {
      button == selectedButton ? button.selected() : button.unselected()
    }
  }
}
