//
//  BackupRecoveryWordsCell.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/28/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class BackupRecoveryWordsCell: UICollectionViewCell, AccessibleViewSettable {

  @IBOutlet var wordLabel: UILabel!
  @IBOutlet var statusLabel: UILabel!

  func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (wordLabel, .backupRecoveryWordsCell(.wordLabel))
    ]
  }
  override func awakeFromNib() {
    super.awakeFromNib()

    setAccessibilityIdentifiers()

    wordLabel.font = CKFont.bold(35)
    wordLabel.textColor = Theme.Color.darkBlueText.color

    statusLabel.font = CKFont.medium(14)
    statusLabel.textColor = Theme.Color.grayText.color
  }

  func load(with data: BackupRecoveryWordCellData) {
    wordLabel.text = data.word.uppercased()
    statusLabel.text = "word \(data.currentIndex) of \(data.total)"
  }
}
