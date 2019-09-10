//
//  TwitterShareButton.swift
//  DropBit
//
//  Created by Ben Winters on 8/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class TwitterShareButton: PrimaryActionButton {

  override func awakeFromNib() {
    super.awakeFromNib()
    self.configure(
      withTitle: "SHARE",
      font: .medium(10),
      foregroundColor: .lightGrayText,
      imageName: "twitterBird",
      imageSize: CGSize(width: 10, height: 10),
      titleEdgeInsets: UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2),
      contentEdgeInsets: UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 4)
    )
  }
}
