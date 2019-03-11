//
//  PopoverViewControllerType.swift
//  DropBit
//
//  Created by Mitch on 12/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

@objc protocol PopoverViewControllerType: class {
  var containerView: UIView! { get set }
  func dismissPopoverViewController()
}

extension PopoverViewControllerType where Self: BaseViewController {

  func addDismissibleTapToBackground() {
    let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissPopoverViewController))
    view.addGestureRecognizer(gestureRecognizer)

    containerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: nil))
  }
}
