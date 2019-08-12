//
//  TryLightningViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/7/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class TryLightningViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var containerView: UIView!
  @IBOutlet var lightningImageView: UIImageView!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var yesButton: UIButton!
  @IBOutlet var noButton: UIButton!

  static func newInstance(yesCompletionHandler completion: @escaping () -> Void,
                          noCompletionHandler noCompletion: @escaping () -> Void) -> TryLightningViewController {
    let tryLightningViewController = TryLightningViewController.makeFromStoryboard()
    tryLightningViewController.yesCompletion = completion
    tryLightningViewController.noCompletion = noCompletion
    tryLightningViewController.modalPresentationStyle = .overFullScreen
    tryLightningViewController.modalTransitionStyle = .crossDissolve
    return tryLightningViewController
  }

  private var yesCompletion: (() -> Void)?
  private var noCompletion: (() -> Void)?

  override func viewDidLoad() {
    super.viewDidLoad()

    view.isOpaque = false
    view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.85)

    titleLabel.font = .medium(17)
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

  @IBAction func noButtonWasTouched() {
    dismiss(animated: true, completion: nil)
    noCompletion?()
  }

  @IBAction func yesButtonWasTouched() {
    dismiss(animated: true, completion: nil)
    yesCompletion?()
  }

}
