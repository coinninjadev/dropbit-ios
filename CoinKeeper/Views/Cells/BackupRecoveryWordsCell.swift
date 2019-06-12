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

    wordLabel.font = .bold(35)
    wordLabel.textColor = .darkBlueText

    statusLabel.font = .medium(14)
    statusLabel.textColor = .darkGrayText
  }

  func load(with data: BackupRecoveryWordCellData) {
    wordLabel.text = data.word.uppercased()
    statusLabel.text = "word \(data.currentIndex) of \(data.total)"
  }
}
