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

  fileprivate weak var delegate: RecoveryWordsIntroViewControllerDelegate!

  private var recoveryWords: [String] = []

  static func newInstance(words: [String], delegate: RecoveryWordsIntroViewControllerDelegate) -> RecoveryWordsIntroViewController {
    let vc = RecoveryWordsIntroViewController.makeFromStoryboard()
    vc.recoveryWords = words
    vc.delegate = delegate
    return vc
  }

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
    titleLabel.font = .medium(19)
    subtitle1Label.font = .medium(15)
    subtitle2Label.font = .regular(13)
    restoreInfoLabel.font = .regular(15)
    estimatedTimeLabel.font = .regular(13)

    [titleLabel, subtitle1Label, restoreInfoLabel].forEach { $0?.textColor = .darkGrayText }
    [subtitle2Label, estimatedTimeLabel].forEach { $0?.textColor = .darkBlueText }

    if delegate.verifyIfWordsAreBackedUp() {
      proceedButton.setTitle("VIEW RECOVERY WORDS", for: .normal)
      estimatedTimeLabel.isHidden = true
    } else {
      proceedButton.setTitle("WRITE DOWN WORDS + BACK UP", for: .normal)
      estimatedTimeLabel.isHidden = false
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
    delegate.viewController(self, didChooseToBackupWords: recoveryWords)
  }

  @IBAction func skipButtonTapped(_ sender: UIButton) {
    delegate.viewController(self, didSkipWords: recoveryWords)
  }
}
