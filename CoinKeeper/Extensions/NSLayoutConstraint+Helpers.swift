//
//  NSLayoutConstraint+Helpers.swift
//  DropBit
//
//  Created by Ben Winters on 8/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIView {

  func constrain(to targetView: UIView,
                 topConstant: CGFloat = 0,
                 bottomConstant: CGFloat = 0,
                 leadingConstant: CGFloat = 0,
                 trailingConstant: CGFloat = 0) {
    targetView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      self.topAnchor.constraint(equalTo: targetView.topAnchor, constant: topConstant),
      self.bottomAnchor.constraint(equalTo: targetView.bottomAnchor, constant: bottomConstant),
      self.leadingAnchor.constraint(equalTo: targetView.leadingAnchor, constant: leadingConstant),
      self.trailingAnchor.constraint(equalTo: targetView.trailingAnchor, constant: trailingConstant)
      ])
  }

}
