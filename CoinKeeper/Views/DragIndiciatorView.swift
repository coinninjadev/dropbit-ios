//
//  DragIndiciatorView.swift
//  DropBit
//
//  Created by Mitch on 10/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class DragIndicatiorView: UIView {

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  private func initialize() {
    backgroundColor = Theme.Color.dragIndiciator.color
    applyCornerRadius(2.5)

    setupConstraints()
  }

  private func setupConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    heightAnchor.constraint(equalToConstant: 5.0).isActive = true
    widthAnchor.constraint(equalToConstant: 50.0).isActive = true
  }
}
