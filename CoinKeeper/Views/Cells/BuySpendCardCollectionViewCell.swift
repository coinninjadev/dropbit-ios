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
  @IBOutlet var purposeLabel: UILabel! {
    didSet {
      purposeLabel.font = .secondaryButtonTitle
      purposeLabel.textColor = .lightGrayText
    }
  }
  @IBOutlet var partnerStackView: UIStackView!

  override func awakeFromNib() {
    super.awakeFromNib()
    applyCornerRadius(8)
  }

  private var userSelected = false
  override var isSelected: Bool {
    didSet {
      userSelected = true
      animate(highlighted: userSelected)
    }
  }

  private func animate(highlighted: Bool) {
    let animationOptions: UIView.AnimationOptions = [.allowUserInteraction, .curveEaseInOut]
    UIView.animate(
      withDuration: 0.1,
      delay: 0,
      usingSpringWithDamping: 1,
      initialSpringVelocity: 0,
      options: animationOptions,
      animations: { self.transform = .init(scaleX: 0.95, y: 0.95) },
      completion: { _ in
        UIView.animate(
          withDuration: 0.1,
          delay: 0,
          usingSpringWithDamping: 1,
          initialSpringVelocity: 0,
          options: animationOptions,
          animations: { self.transform = .identity },
          completion: nil
        )
      }
    )
  }

  func load(with viewModel: BuySpendCardViewModel) {
    backgroundTopView.backgroundColor = viewModel.cardColor
    purposeImageView.image = viewModel.purposeImage
    purposeLabel.text = viewModel.purposeText
    viewModel.partnerImages
      .forEach { (image) in
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        self.partnerStackView.addArrangedSubview(imageView)
      }
  }

}
