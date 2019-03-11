//
//  RecoveryWordsIntroViewController.swift
//  DropBit
//
//  Created by BJ Miller on 11/5/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol RecoveryWordsIntroViewControllerDelegate: AnyObject {
  func viewController(_ viewController: UIViewController, didChooseToBackupWords words: [String], in flow: RecoveryWordsFlow)
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

  var flow: RecoveryWordsFlow = .createWallet
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
    titleLabel.font = Theme.Font.onboardingTitle.font
    subtitle1Label.font = Theme.Font.recoverySubtitle1.font
    subtitle2Label.font = Theme.Font.recoverySubtitle2.font
    restoreInfoLabel.font = Theme.Font.onboardingSubtitle.font
    estimatedTimeLabel.font = Theme.Font.recoverySubtitle2.font

    [titleLabel, subtitle1Label, restoreInfoLabel].forEach { $0?.textColor = Theme.Color.grayText.color }
    [subtitle2Label, estimatedTimeLabel].forEach { $0?.textColor = Theme.Color.darkBlueText.color }

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
    switch flow {
    case .settings:
      skipButton.isHidden = true
      closeButton.isHidden = false
    case .createWallet:
      skipButton.isHidden = false
      closeButton.isHidden = true
    }
  }

  @IBAction func closeButtonTapped(_ sender: UIButton) {
    dismiss(animated: true, completion: nil)
  }

  @IBAction func proceedButtonTapped(_ sender: UIButton) {
    coordinationDelegate?.viewController(self, didChooseToBackupWords: recoveryWords, in: flow)
  }

  @IBAction func skipButtonTapped(_ sender: UIButton) {
    coordinationDelegate?.viewController(self, didSkipWords: recoveryWords)
  }
}
