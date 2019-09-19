//
//  DarkActionButton.swift
//  DropBit
//
//  Created by Mitchell Malleo on 9/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class DarkActionButton: UIButton {

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .darkBlueBackground
    applyCornerRadius(4)
    setTitleColor(.whiteText, for: .normal)
    titleLabel?.font = .primaryButtonTitle
    imageView?.tintColor = .white
  }
}
