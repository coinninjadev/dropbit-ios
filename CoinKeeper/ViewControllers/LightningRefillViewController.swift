//
//  LightningRefillViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/6/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class LightningRefillViewController: BaseViewController {

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

    customAmountButton.setTitleColor(.white, for: .normal)
    remindMeLaterButton.setTitleColor(.white, for: .normal)
  }

  private func styleButton(_ button: UIButton) {
    button.applyCornerRadius(4)
    button.backgroundColor = .white
    button.setTitleColor(.lightningBlue, for: .normal)
    button.titleLabel?.font = .medium(19)
  }
}
