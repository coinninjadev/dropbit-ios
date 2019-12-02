//
//  TwitterAvatarView.swift
//  DropBit
//
//  Created by Ben Winters on 8/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class AvatarView: UIView {

  enum Kind {
    case generic
    case twitter
  }

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

  /// `logoBackgroundColor` is used for the small circle behind the Twitter bird
  func configure(with image: UIImage, logoBackgroundColor: UIColor, kind: Kind) {
    avatarImageView.backgroundColor = logoBackgroundColor
    twitterLogoImageView.backgroundColor = logoBackgroundColor
    avatarImageView.image = image
  }

  private func initialize() {
    let logoDiameter: CGFloat = 20 //larger than the actual logo image

    addImageSubviews()
    addImageConstraints(logoDiameter: logoDiameter)
    configureImageViews(logoDiameter: logoDiameter)
  }

  private func addImageSubviews() {
    self.avatarImageView = UIImageView(image: nil)
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(self.avatarImageView)
    self.twitterLogoImageView = UIImageView(image: UIImage(named: "avatarTwitterBird"))
    self.twitterLogoImageView.translatesAutoresizingMaskIntoConstraints = false
    self.addSubview(twitterLogoImageView)
  }

  private func addImageConstraints(logoDiameter: CGFloat) {
    let logoRadius = logoDiameter / 2
    avatarImageView.constrain(to: self, topConstant: logoRadius, bottomConstant: -logoRadius)

    //equal width and height determined by externally set width constraint on TwitterAvatarView
    let equalWidthHeightConstraint = avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor, multiplier: 1.0)

    NSLayoutConstraint.activate([
      equalWidthHeightConstraint,
      twitterLogoImageView.widthAnchor.constraint(equalToConstant: logoDiameter),
      twitterLogoImageView.heightAnchor.constraint(equalToConstant: logoDiameter),
      twitterLogoImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
      twitterLogoImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
      ])
  }

  private func configureImageViews(logoDiameter: CGFloat) {
    avatarImageView.contentMode = .scaleAspectFit
    twitterLogoImageView.contentMode = .center

    let avatarRadius = self.frame.width / 2 //avatarImageView.frame.width is not yet updated with the above constraints
    let logoRadius = logoDiameter / 2
    avatarImageView.applyCornerRadius(avatarRadius)
    twitterLogoImageView.applyCornerRadius(logoRadius)
  }

}
