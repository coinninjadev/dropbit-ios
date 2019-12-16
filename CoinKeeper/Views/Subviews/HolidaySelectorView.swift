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
  func switchUserToHoliday(_ holiday: HolidayType, failure: @escaping CKCompletion)
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

  override var isHidden: Bool {
    set {
      if Date() > Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 3)) ?? Date() {
        super.isHidden = true
      } else {
        super.isHidden = newValue
      }
    }
    get {
      return super.isHidden
    }
  }

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
    guard !selectedButton.isSelected else { return }

    var oldSelectedButton = selectedButton
    for button in buttons where selectedButton !== button {
      if button.isSelected {
        oldSelectedButton = button
      }

      button.isSelected = false
    }

    let failure: CKCompletion = { [weak self] in
      guard let strongSelf = self else { return }
      for button in strongSelf.buttons where oldSelectedButton !== button {
        button.isSelected = false
      }

      oldSelectedButton.isSelected = true
    }

    selectedButton.isSelected = true

    if selectedButton == firstButton {
      delegate?.switchUserToHoliday(.bitcoin, failure: failure)
    } else if selectedButton == secondButton {
      delegate?.switchUserToHoliday(.holiday, failure: failure)
    } else if selectedButton == thirdButton {
      delegate?.switchUserToHoliday(.christmas, failure: failure)
    } else if selectedButton == fourthButton {
      delegate?.switchUserToHoliday(.hanukkah, failure: failure)
    }
  }

}
