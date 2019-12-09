//
//  UIButton+Vertical.swift
//  DropBit
//
//  Created by Mitchell Malleo on 12/4/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {

  func centerVertically(padding: CGFloat = 6.0) {
    guard
      let imageViewSize = self.imageView?.frame.size,
      let titleLabelSize = self.titleLabel?.frame.size else {
        return
    }

    let totalHeight = imageViewSize.height + titleLabelSize.height + padding

    self.imageEdgeInsets = UIEdgeInsets(
      top: -(totalHeight - imageViewSize.height),
      left: 0.0,
      bottom: 0.0,
      right: -titleLabelSize.width
    )

    self.titleEdgeInsets = UIEdgeInsets(
      top: 0.0,
      left: -imageViewSize.width,
      bottom: -(totalHeight - titleLabelSize.height),
      right: 0.0
    )

    self.contentEdgeInsets = UIEdgeInsets(
      top: 20.0,
      left: 0.0,
      bottom: titleLabelSize.height,
      right: 0.0
    )
  }

}
