//
//  EmojiDetailView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 12/2/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class EmojiDetailView: UIView {

  @IBOutlet var emojiLabel: UILabel!
  @IBOutlet var descriptionLabel: UILabel!

  init() {
    super.init(frame: .zero)
    xibSetup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    emojiLabel.font = .systemFont(ofSize: 30)

    descriptionLabel.font = .regular(15)
    descriptionLabel.textColor = .darkBlueText
    descriptionLabel.numberOfLines = 0
  }

}
