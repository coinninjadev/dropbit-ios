//
//  CreateRecoveryWordsCell.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/28/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class CreateRecoveryWordsCell: UICollectionViewCell, AccessibleViewSettable {

  @IBOutlet var wordLabel: UILabel!
  @IBOutlet var statusLabel: UILabel!

  func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (wordLabel, .createRecoveryWordsCell(.wordLabel))
    ]
  }
  override func awakeFromNib() {
    super.awakeFromNib()

    setAccessibilityIdentifiers()

    wordLabel.font = Theme.Font.createRecoveryWord.font
    wordLabel.textColor = Theme.Color.darkBlueText.color

    statusLabel.font = Theme.Font.createRecoveryWordStatus.font
    statusLabel.textColor = Theme.Color.grayText.color
  }

  func load(with data: CreateRecoveryWordCellData) {
    wordLabel.text = data.word.uppercased()
    statusLabel.text = "word \(data.currentIndex) of \(data.total)"
  }
}
