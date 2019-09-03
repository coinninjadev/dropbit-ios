//
//  TwitterAvatarView.swift
//  DropBit
//
//  Created by Ben Winters on 8/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TwitterAvatarView: UIView {

  private(set) var avatarImageView: UIImageView!
  private(set) var twitterLogoImageView: UIImageView!

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  private func initialize() {

    //Add subviews
    self.avatarImageView = UIImageView(image: nil)
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(self.avatarImageView)
    self.twitterLogoImageView = UIImageView(image: UIImage(named: "avatarTwitterBird"))
    self.twitterLogoImageView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(twitterLogoImageView)

    //Set constraints
    let logoViewDiameter: CGFloat = 20 //larger than the actual logo image
    let logoViewRadius = logoViewDiameter / 2
    avatarImageView.constrain(to: self, topConstant: logoViewRadius, bottomConstant: -logoViewRadius)

    //equal width and height determined by externally set width constraint on TwitterAvatarView
    let equalWidthHeightConstraint = avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor, multiplier: 1.0)

    NSLayoutConstraint.activate([
      equalWidthHeightConstraint,
      twitterLogoImageView.widthAnchor.constraint(equalToConstant: logoViewDiameter),
      twitterLogoImageView.heightAnchor.constraint(equalToConstant: logoViewDiameter),
      twitterLogoImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
      twitterLogoImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
      ])

    //Configure image views
    avatarImageView.contentMode = .scaleAspectFit
    twitterLogoImageView.contentMode = .center

    let avatarRadius = self.frame.width / 2 //avatarImageView.frame.width is not yet updated with the above constraints
    avatarImageView.applyCornerRadius(avatarRadius)
    twitterLogoImageView.applyCornerRadius(logoViewRadius)
  }

  /// `logoBackgroundColor` is used for the small circle behind the Twitter bird
  func configure(with image: UIImage, logoBackgroundColor: UIColor) {
    avatarImageView.image = image
    twitterLogoImageView.backgroundColor = logoBackgroundColor
  }

}
