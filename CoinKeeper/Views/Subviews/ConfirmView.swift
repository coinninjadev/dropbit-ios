//
//  ConfirmView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class ConfirmView: UIView {

  @IBOutlet var tapAndHoldLabel: UILabel!
  @IBOutlet var confirmButton: LongPressConfirmButton!

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

    tapAndHoldLabel.textColor = .darkGrayText
    tapAndHoldLabel.font = .medium(13)
  }

  func configure(withStyle style: LongPressConfirmButton.Style) {
    confirmButton.configure(withStyle: style)
  }

}
