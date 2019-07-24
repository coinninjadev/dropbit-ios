//
//  VerifyRecoveryWordCell.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol VerifyRecoveryWordSelectionDelegate: AnyObject {
  func cell(_ cell: VerifyRecoveryWordCell, didSelectWord word: String, withCellData cellData: VerifyRecoveryWordCellData)
}

class VerifyRecoveryWordCell: UICollectionViewCell, AccessibleViewSettable {

  // MARK: outlets
  @IBOutlet var wordLabelBackgroundView: UIView!
  @IBOutlet var spacerView: UIView!
  @IBOutlet var wordLabel: UILabel!
  @IBOutlet var word1Button: PrimaryActionButton!
  @IBOutlet var word2Button: PrimaryActionButton!
  @IBOutlet var word3Button: PrimaryActionButton!
  @IBOutlet var word4Button: PrimaryActionButton!
  @IBOutlet var word5Button: PrimaryActionButton!

  // MARK: variables
  private var wordButtons: [UIButton] {
    return [word1Button, word2Button, word3Button, word4Button, word5Button]
  }

  private var cellData: VerifyRecoveryWordCellData?
  weak var selectionDelegate: VerifyRecoveryWordSelectionDelegate?

  // MARK: view instantiation
  override func awakeFromNib() {
    super.awakeFromNib()
    wordLabelBackgroundView.backgroundColor = .extraLightGrayBackground
    wordLabelBackgroundView.layer.borderColor = UIColor.mediumGrayBorder.cgColor
    wordLabelBackgroundView.layer.borderWidth = 1.0
    wordLabelBackgroundView.applyCornerRadius(4)
    spacerView.backgroundColor = .clear
    wordLabel.font = .primaryButtonTitle
    wordLabel.textColor = .darkBlueText
  }

  func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self, .verifyRecoveryWordsCell(.page)),
      (wordLabel, .verifyRecoveryWordsCell(.currentIndexLabel))
    ]
  }

  func load(with cellData: VerifyRecoveryWordCellData) {
    self.cellData = cellData
    self.selectionDelegate = cellData.selectionDelegate
    let humanReadableIndex = cellData.selectedIndex + 1
    wordLabel.text = "Select word \(humanReadableIndex)"
    let possibleWords = cellData.possibleWords
    zip(wordButtons, possibleWords).forEach { button, possibleWord in button.setTitle(possibleWord, for: .normal) }
    setAccessibilityIdentifiers()
  }

  // MARK: actions
  @IBAction func buttonTapped(_ sender: UIButton) {
    guard let title = sender.title(for: .normal), let cellData = cellData else { return }
    selectionDelegate?.cell(self, didSelectWord: title, withCellData: cellData)
  }
}
