//
//  RecoveryWordsIntroViewController.swift
//  DropBit
//
//  Created by BJ Miller on 11/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol RecoveryWordsIntroViewControllerDelegate: AnyObject {
  func viewController(_ viewController: UIViewController, didChooseToBackupWords words: [String])
  func verifyIfWordsAreBackedUp() -> Bool
  func viewController(_ viewController: UIViewController, didSkipWords words: [String])
}

final class RecoveryWordsIntroViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var subtitle1Label: UILabel!
  @IBOutlet var subtitle2Label: UILabel!
  @IBOutlet var writeImageView: UIImageView!
  @IBOutlet var restoreInfoLabel: UILabel!
  @IBOutlet var estimatedTimeLabel: UILabel!
  @IBOutlet var proceedButton: PrimaryActionButton!
  @IBOutlet var skipButton: SecondaryActionButton!
  @IBOutlet var closeButton: UIButton!

  var coordinationDelegate: RecoveryWordsIntroViewControllerDelegate? {
    return generalCoordinationDelegate as? RecoveryWordsIntroViewControllerDelegate
  }

  var recoveryWords: [String] = []

  override func viewDidLoad() {
    super.viewDidLoad()

    configureUI()
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (view, .recoveryWordsIntro(.page)),
      (skipButton, .recoveryWordsIntro(.skip)),
      (proceedButton, .recoveryWordsIntro(.backup))
    ]
  }

  private func configureUI() {
    titleLabel.font = CKFont.medium(19)
    subtitle1Label.font = CKFont.medium(15)
    subtitle2Label.font = CKFont.regular(13)
    restoreInfoLabel.font = CKFont.regular(15)
    estimatedTimeLabel.font = CKFont.regular(13)

    [titleLabel, subtitle1Label, restoreInfoLabel].forEach { $0?.textColor = .grayText }
    [subtitle2Label, estimatedTimeLabel].forEach { $0?.textColor = .darkBlueText }

    switch coordinationDelegate?.verifyIfWordsAreBackedUp() {
    case false?:
      proceedButton.setTitle("WRITE DOWN WORDS + BACK UP", for: .normal)
      estimatedTimeLabel.isHidden = false
    case true?:
      proceedButton.setTitle("VIEW RECOVERY WORDS", for: .normal)
      estimatedTimeLabel.isHidden = true
    default:
      break
    }

    skipButton.setTitle("SKIP AND BACK UP LATER", for: .normal)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    skipButton.isHidden = true
    closeButton.isHidden = false
  }

  @IBAction func closeButtonTapped(_ sender: UIButton) {
    dismiss(animated: true, completion: nil)
  }

  @IBAction func proceedButtonTapped(_ sender: UIButton) {
    coordinationDelegate?.viewController(self, didChooseToBackupWords: recoveryWords)
  }

  @IBAction func skipButtonTapped(_ sender: UIButton) {
    coordinationDelegate?.viewController(self, didSkipWords: recoveryWords)
  }
}
