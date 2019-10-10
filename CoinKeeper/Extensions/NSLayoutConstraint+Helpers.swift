//
//  NSLayoutConstraint+Helpers.swift
//  DropBit
//
//  Created by Ben Winters on 8/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIView {

  ///Pass nil to not add a constraint to that side
  func constrain(to targetView: UIView,
                 topConstant: CGFloat? = 0,
                 bottomConstant: CGFloat? = 0,
                 leadingConstant: CGFloat? = 0,
                 trailingConstant: CGFloat? = 0) {
    targetView.translatesAutoresizingMaskIntoConstraints = false

    let topConstraint = topConstant.flatMap { self.topAnchor.constraint(equalTo: targetView.topAnchor, constant: $0) }
    let bottomConstraint = bottomConstant.flatMap { self.bottomAnchor.constraint(equalTo: targetView.bottomAnchor, constant: $0) }
    let leadingConstraint = leadingConstant.flatMap { self.leadingAnchor.constraint(equalTo: targetView.leadingAnchor, constant: $0) }
    let trailingConstraint = trailingConstant.flatMap { self.trailingAnchor.constraint(equalTo: targetView.trailingAnchor, constant: $0) }

    let desiredConstraints: [NSLayoutConstraint] = [topConstraint, bottomConstraint, leadingConstraint, trailingConstraint].compactMap { $0 }
    NSLayoutConstraint.activate(desiredConstraints)
  }

}
