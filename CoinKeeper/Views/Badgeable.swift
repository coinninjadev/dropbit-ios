//
//  Badgeable.swift
//  DropBit
//
//  Created by Ben Winters on 10/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

struct ViewOffset {
  var dx: CGFloat
  var dy: CGFloat

  static var none: ViewOffset {
    return ViewOffset(dx: 0, dy: 0)
  }
}

protocol Badgeable: AnyObject {

  /// A dictionary of topic-status pairs that if they exist in the badgeInfo dictionary
  /// provided to updateBadge() will result in a badge being shown.
  var badgeDisplayCriteria: BadgeInfo { get }

  var badgeTarget: UIView { get }
  var badgeOffset: ViewOffset { get }
}

extension Badgeable {
  var badgeOffset: ViewOffset {
    return ViewOffset.none
  }
}

extension Badgeable where Self: UIView {
  var badgeTarget: UIView {
    return self
  }
}

extension Badgeable {

  func updateBadge(with badgeInfo: BadgeInfo) {
    var shouldShow = false
    for (topic, statusOptionSet) in badgeInfo {
      if let validStatusOptionSet = badgeDisplayCriteria[topic] {
        // Show badge if there is any overlap between the option sets
        if statusOptionSet.intersection(validStatusOptionSet).isNotEmpty {
          shouldShow = true
          break
        }
      }
    }
    DispatchQueue.main.async {
      self.showBadge(shouldShow)
    }
  }

  private var badgeIsShown: Bool {
    let badgeSubview = badgeTarget.subviews.first { $0 is BadgeView }
    return badgeSubview != nil
  }

  private func showBadge(_ shouldShow: Bool) {
    if shouldShow {
      if !badgeIsShown {
        addBadgeSubview()
      }

    } else {
      for subview in badgeTarget.subviews where subview is BadgeView {
        subview.removeFromSuperview()
      }
    }
  }

  private func addBadgeSubview() {
    //add badge view as subview
    badgeTarget.translatesAutoresizingMaskIntoConstraints = false

    let badge = BadgeView()
    badge.translatesAutoresizingMaskIntoConstraints = false

    let diameter = BadgeView.standardDiameter
    badge.applyCornerRadius(diameter/2) // create circle

    badgeTarget.addSubview(badge)

    NSLayoutConstraint.activate([
      badge.widthAnchor.constraint(equalToConstant: diameter),
      badge.heightAnchor.constraint(equalToConstant: diameter),
      badge.topAnchor.constraint(equalTo: badgeTarget.topAnchor, constant: badgeOffset.dy),
      badge.rightAnchor.constraint(equalTo: badgeTarget.rightAnchor, constant: badgeOffset.dx)
      ]
    )
  }

}
