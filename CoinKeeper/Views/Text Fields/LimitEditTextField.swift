//
//  LimitEditTextField.swift
//  DropBit
//
//  Created by Mitchell on 7/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class LimitEditTextField: UITextField {
  var shouldDisableActions: Bool = true
  var disabledActions: [Selector] = [#selector(UIResponderStandardEditActions.paste(_:)), #selector(UIResponderStandardEditActions.cut(_:)),
                                     #selector(UIResponderStandardEditActions.selectAll(_:)), #selector(UIResponderStandardEditActions.select(_:)),
                                     #selector(UIResponderStandardEditActions.delete(_:)), #selector(UIResponderStandardEditActions.copy(_:))]

  open override func target(forAction action: Selector, withSender sender: Any?) -> Any? {
    if disabledActions.contains(action) && shouldDisableActions {
      return nil
    }
    return super.target(forAction: action, withSender: sender)
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = UIColor.clear
    textColor = .lightBlueTint
    keyboardType = .decimalPad
    font = .regular(30)
    shouldDisableActions = true
  }
}
