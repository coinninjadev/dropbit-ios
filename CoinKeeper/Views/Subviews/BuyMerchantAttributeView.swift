//
//  BuyMerchantAttributeView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class BuyMerchantAttributeView: UIView {

  @IBOutlet var imageView: UIImageView!
  @IBOutlet var descriptionLabel: UILabel!

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  private func initialize() {
    xibSetup()
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    descriptionLabel.font = .light(14)
  }

  func load(with model: BuyMerchantAttribute) {
    imageView.image = model.image
    descriptionLabel.text = model.description
  }
}
