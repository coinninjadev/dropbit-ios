//
//  HolidaySelectorView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 12/4/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol HolidaySelectorViewDelegate: AnyObject {
  func switchUserToHoliday(_ holiday: HolidayType, success: @escaping CKCompletion)
}

class HolidaySelectorView: UIView {

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var firstButton: VerticalCenterButton!
  @IBOutlet var secondButton: VerticalCenterButton!
  @IBOutlet var thirdButton: VerticalCenterButton!
  @IBOutlet var fourthButton: VerticalCenterButton!

  lazy private var buttons: [UIButton] = [firstButton, secondButton, thirdButton, fourthButton]

  weak var delegate: HolidaySelectorViewDelegate?

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    backgroundColor = .darkBlueBackground

    titleLabel.font = .bold(17)
    titleLabel.adjustsFontSizeToFitWidth = true
    titleLabel.minimumScaleFactor = 0.50
    titleLabel.textColor = .neonGreen

    detailLabel.font = .regular(13)
    detailLabel.textColor = .white

    applyCornerRadius(10)

    firstButton.setTitle("Bitcoin", for: .normal)
    secondButton.setTitle("Holiday", for: .normal)
    thirdButton.setTitle("Christmas", for: .normal)
    fourthButton.setTitle("Hanukkah", for: .normal)
  }

  func selectButton(type: HolidayType) {
    let button: UIButton
    switch type {
    case .bitcoin:
      button = firstButton
    case .holiday:
      button = secondButton
    case .christmas:
      button = thirdButton
    case .hanukkah:
      button = fourthButton
    }

    button.isSelected = true
  }

  @IBAction func holidayButtonWasTouched(_ button: UIButton) {
    selectButton(button)
  }

  private func selectButton(_ selectedButton: UIButton) {
    let success: CKCompletion = { [weak self] in
      guard let strongSelf = self else { return }

      for button in strongSelf.buttons where selectedButton !== button {
        button.isSelected = false
      }

      selectedButton.isSelected = true
    }

    if selectedButton == firstButton {
      delegate?.switchUserToHoliday(.bitcoin, success: success)
    } else if selectedButton == secondButton {
      delegate?.switchUserToHoliday(.holiday, success: success)
    } else if selectedButton == thirdButton {
      delegate?.switchUserToHoliday(.christmas, success: success)
    } else if selectedButton == fourthButton {
      delegate?.switchUserToHoliday(.hanukkah, success: success)
    }
  }

}
