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
  func lowAmountButtonWasTouched()
  func mediumAmountButtonWasTouched()
  func maxAmountButtonWasTouched()
  func customAmountButtonWasTouched()
  func dontAskMeAgainButtonWasTouched()
}

class LightningRefillViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var containerView: UIView!
  @IBOutlet var lightningImageView: UIImageView!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var minMaxLabel: UILabel!
  @IBOutlet var lowAmountButton: LightningActionButton!
  @IBOutlet var mediumAmountButton: LightningActionButton!
  @IBOutlet var maxAmountButton: LightningActionButton!
  @IBOutlet var customAmountButton: LightningActionButton!
  @IBOutlet var remindMeLaterButton: UIButton!
  @IBOutlet var dontAskMeAgainButton: UIButton!

  weak var delegate: LightningRefillViewControllerDelegate?

  static func newInstance() -> LightningRefillViewController {
    let viewController = LightningRefillViewController.makeFromStoryboard()
    viewController.modalPresentationStyle = .overFullScreen
    viewController.modalTransitionStyle = .crossDissolve
    return viewController
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.isOpaque = false
    view.backgroundColor = UIColor.black.withAlphaComponent(0.85)

    titleLabel.font = .medium(17)
    titleLabel.textColor = .white

    detailLabel.font = .regular(13)
    detailLabel.textColor = .neonGreen

    minMaxLabel.font = .regular(12)
    minMaxLabel.textColor = .white

    containerView.applyCornerRadius(10)

    remindMeLaterButton.setTitleColor(.neonGreen, for: .normal)
    dontAskMeAgainButton.setTitleColor(.white, for: .normal)
  }

  @IBAction func lowAmountButtonWasTouched() {
    dismiss(animated: true, completion: nil)
    delegate?.lowAmountButtonWasTouched()
  }

  @IBAction func mediumAmountButtonWasTouched() {
    dismiss(animated: true, completion: nil)
    delegate?.mediumAmountButtonWasTouched()
  }

  @IBAction func maxAmountButtonWasTouched() {
    dismiss(animated: true, completion: nil)
    delegate?.maxAmountButtonWasTouched()
  }

  @IBAction func customAmountButtonWasTouched() {
    dismiss(animated: true, completion: nil)
    delegate?.customAmountButtonWasTouched()
  }

  @IBAction func remindMeLaterButtonWasTouched() {
    dismiss(animated: true, completion: nil)
  }

  @IBAction func dontRemindMeButtonWasTouched() {
    dismiss(animated: true, completion: nil)
    delegate?.dontAskMeAgainButtonWasTouched()
  }
}
