//
//  UIViewController+ToolbarUtilities.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {

  func setupKeyboardDoneButton(for views: [UITextField], action: Selector?) {
    let keypadToolbar: UIToolbar = UIToolbar()
    let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: action)

    keypadToolbar.items = [doneButton]
    keypadToolbar.sizeToFit()

    for view in views {
      view.inputAccessoryView = keypadToolbar
    }
  }
}
