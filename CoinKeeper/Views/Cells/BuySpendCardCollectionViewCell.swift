//
//  BuySpendCardCollectionViewCell.swift
//  DropBit
//
//  Created by BJ Miller on 4/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

struct BuySpendCardViewModel {
  let purposeImage: UIImage
  let purposeText: String
  let cardColor: UIColor
  let partnerImages: [UIImage]
}

class BuySpendCardCollectionViewCell: UICollectionViewCell {

  @IBOutlet var backgroundTopView: UIView!
  @IBOutlet var backgroundBottomView: UIView!
  @IBOutlet var purposeImageView: UIImageView!
  @IBOutlet var purposeLabel: UILabel!
  @IBOutlet var partnerStackView: UIStackView!

  func load(with viewModel: BuySpendCardViewModel) {
    backgroundTopView.backgroundColor = viewModel.cardColor
    purposeImageView.image = viewModel.purposeImage
    purposeLabel.text = viewModel.purposeText
    viewModel.partnerImages
      .map { UIImageView(image: $0) }
      .forEach { self.partnerStackView.addArrangedSubview($0) }
  }

}
