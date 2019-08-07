//
//  LightningRefillViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol LightningRefillViewControllerDelegate: class {
  func fiveButtonWasTouched()
  func twentyButtonWasTouched()
  func hundredButtonWasTouched()
  func customAmountButtonWasTouched()
  func remindMeLaterButtonWasTouched()
}

class LightningRefillViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var containerView: UIView!
  @IBOutlet var lightningImageView: UIImageView!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var minMaxLabel: UILabel!
  @IBOutlet var fiveButton: UIButton!
  @IBOutlet var twentyButton: UIButton!
  @IBOutlet var hundredButton: UIButton!
  @IBOutlet var customAmountButton: UIButton!
  @IBOutlet var remindMeLaterButton: UIButton!

  weak var delegate: LightningRefillViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    titleLabel.font = .medium(19)
    titleLabel.textColor = .white

    detailLabel.font = .regular(13)
    detailLabel.textColor = .neonGreen

    minMaxLabel.font = .regular(12)
    minMaxLabel.textColor = .white

    styleButton(fiveButton)
    styleButton(twentyButton)
    styleButton(hundredButton)

    containerView.applyCornerRadius(10)

    customAmountButton.setTitleColor(.white, for: .normal)
    remindMeLaterButton.setTitleColor(.white, for: .normal)
  }

  private func styleButton(_ button: UIButton) {
    button.applyCornerRadius(4)
    button.backgroundColor = .white
    button.setTitleColor(.lightningBlue, for: .normal)
    button.titleLabel?.font = .medium(19)
  }

  @IBAction func fiveButtonWasTouched() {
    delegate?.fiveButtonWasTouched()
  }

  @IBAction func twentyButtonWasTouched() {
    delegate?.twentyButtonWasTouched()
  }

  @IBAction func hundredButtonWasTouched() {
    delegate?.hundredButtonWasTouched()
  }

  @IBAction func customAmountButtonWasTouched() {
    delegate?.customAmountButtonWasTouched()
  }

  @IBAction func remindMeLaterButtonWasTouched() {
    delegate?.remindMeLaterButtonWasTouched()
  }
}
