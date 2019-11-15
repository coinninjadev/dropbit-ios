//
//  BuyMerchantAttributeView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol BuyMerchantAttributeViewDelegate: AnyObject {
  func attributeViewWasTouched(with url: URL)
}

class BuyMerchantAttributeView: UIView {

  @IBOutlet var imageView: UIImageView!
  @IBOutlet var descriptionLabel: UILabel!
  @IBOutlet var linkButton: UIButton!

  weak var delegate: BuyMerchantAttributeViewDelegate?
  var viewModel: BuyMerchantAttribute?

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

    backgroundColor = .lightGrayBackground
  }

  func load(with model: BuyMerchantAttribute) {
    imageView.image = model.image
    viewModel = model

    if model.link != nil {
      let normalString = NSMutableAttributedString.regular(model.description,
                                                          size: 14, color: .darkBlueText)
      normalString.underlineText()
      linkButton.setAttributedTitle(normalString, for: .normal)

      linkButton.isHidden = false
      descriptionLabel.isHidden = true
    } else {
      descriptionLabel.attributedText = NSMutableAttributedString.regular(model.description,
                                                                         size: 14, color: .darkBlueText)

      linkButton.isHidden = true
      descriptionLabel.isHidden = false
    }

  }

  @IBAction func linkButtonWasTapped() {
    guard let link = viewModel?.link, let url = URL(string: link) else { return }
    delegate?.attributeViewWasTouched(with: url)
  }
}
