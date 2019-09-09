//
//  LightningTooltipListItem.swift
//  DropBit
//
//  Created by Ben Winters on 7/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class LightningTooltipListItem: UIView {

  override init(frame: CGRect) {
    super.init(frame: frame)

    self.translatesAutoresizingMaskIntoConstraints = false
    self.backgroundColor = .clear
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  convenience init(imageName: String, text: String) {
    self.init(frame: .zero)
    let imageView = UIImageView(image: UIImage(named: imageName))
    imageView.contentMode = .center
    imageView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(imageView)

    let label = UILabel(frame: .zero)
    label.translatesAutoresizingMaskIntoConstraints = false
    label.textAlignment = .center
    label.numberOfLines = 0
    label.text = text
    label.textColor = .darkBlueText
    label.font = .bold(12)
    self.addSubview(label)

    NSLayoutConstraint.activate([
      imageView.widthAnchor.constraint(equalToConstant: 44),
      imageView.heightAnchor.constraint(equalToConstant: 30),
      label.widthAnchor.constraint(equalToConstant: 90),

      imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
      label.centerXAnchor.constraint(equalTo: self.centerXAnchor),

      imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 4),
      label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
      label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 4)
      ]
    )
  }
}
