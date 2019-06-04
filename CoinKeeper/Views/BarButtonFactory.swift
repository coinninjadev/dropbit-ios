//
//  BarButtonFactory.swift
//  DropBit
//
//  Created by BJ Miller on 11/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class BarButtonFactory {
  static func skipButton(withTarget target: UIViewController, selector: Selector) -> UIBarButtonItem {
    let skipButton = UIBarButtonItem(title: "skip", style: .plain, target: target, action: selector)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: CKFont.regular(15),
      .foregroundColor: Theme.Color.darkBlueButton.color
    ]
    skipButton.setTitleTextAttributes(attributes, for: .normal)
    return skipButton
  }
}
