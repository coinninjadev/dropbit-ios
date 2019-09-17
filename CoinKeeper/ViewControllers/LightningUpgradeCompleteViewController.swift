//
//  LightningUpgradeCompleteViewController.swift
//  DropBit
//
//  Created by BJ Miller on 9/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol LightningUpgradeCompleteViewControllerDelegate: AnyObject {
  func viewControllerDidSelectGoToWallet(_ viewController: LightningUpgradeCompleteViewController)
  func viewControllerDidSelectGetRecoveryWords(_ viewController: LightningUpgradeCompleteViewController)
}

final class LightningUpgradeCompleteViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var overlayView: LightningUpgradeGradientOverlayView!
  @IBOutlet var goToWalletButton: PrimaryActionButton!
  @IBOutlet var getNewRecoveryWordsButton: PrimaryActionButton!
  @IBOutlet var upgradeCompleteLabel: UILabel!
  @IBOutlet var lightningReadyLabel: UILabel!

  private(set) weak var delegate: LightningUpgradeCompleteViewControllerDelegate!

  static func newInstance(withDelegate delegate: LightningUpgradeCompleteViewControllerDelegate) -> LightningUpgradeCompleteViewController {
    let controller = LightningUpgradeCompleteViewController.makeFromStoryboard()
    controller.delegate = delegate
    return controller
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    styleInitialUI()
  }

  private func styleInitialUI() {
    goToWalletButton.style = .white(enabled: true)
    goToWalletButton.setTitleColor(.mediumPurple, for: .normal)
    goToWalletButton.setTitle("GO TO WALLET", for: .normal)
    getNewRecoveryWordsButton.style = .mediumPurple
    getNewRecoveryWordsButton.setTitle("GET NEW RECOVERY WORDS", for: .normal)
    upgradeCompleteLabel.textColor = .neonGreen
    upgradeCompleteLabel.font = .regular(17)
    lightningReadyLabel.font = .regular(17)
    lightningReadyLabel.textColor = .white
    lightningReadyLabel.text = "Your upgraded wallet\nis Lightning ready!"
  }

  @IBAction func goToWallet(_ sender: Any) {
    delegate.viewControllerDidSelectGoToWallet(self)
  }

  @IBAction func getNewRecoveryWords(_ sender: Any) {
    delegate.viewControllerDidSelectGetRecoveryWords(self)
  }
}
