//
//  TryLightningViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/7/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol TryLightningViewControllerDelegate: class {
  func yesButtonWasTouched()
  func noButtonWasTouched()
}

class TryLightningViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var containerView: UIView!
  @IBOutlet var lightningImageView: UIImageView!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var yesButton: UIButton!
  @IBOutlet var noButton: UIButton!

  weak var delegate: TryLightningViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    titleLabel.font = .medium(19)
    titleLabel.textColor = .white

    detailLabel.font = .regular(13)
    detailLabel.textColor = .neonGreen

    yesButton.applyCornerRadius(4)
    yesButton.backgroundColor = .white
    yesButton.setTitleColor(.lightningBlue, for: .normal)
    yesButton.titleLabel?.font = .medium(16)

    containerView.applyCornerRadius(10)

    noButton.setTitleColor(.white, for: .normal)
  }

  @IBAction func fiveButtonWasTouched() {
    delegate?.noButtonWasTouched()
  }

  @IBAction func yesButtonWasTouched() {
    delegate?.yesButtonWasTouched()
  }

}
