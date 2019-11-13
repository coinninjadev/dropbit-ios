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
    descriptionLabel.font = .light(14)

    let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(linkLabelWasTapped))
    addGestureRecognizer(gestureRecognizer)
  }

  func load(with model: BuyMerchantAttribute) {
    imageView.image = model.image
    viewModel = model

    if model.link != nil {
      let normalString = NSMutableAttributedString.medium(model.description, size: 14, color: .darkBlueText)
      normalString.underlineText()
      descriptionLabel.attributedText = normalString
    } else {
      descriptionLabel.attributedText = NSAttributedString(string: model.description)
    }

  }

  @objc func linkLabelWasTapped() {
    guard let link = viewModel?.link, let url = URL(string: link) else { return }
    delegate?.attributeViewWasTouched(with: url)
  }
}
