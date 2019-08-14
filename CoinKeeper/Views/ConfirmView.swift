//
//  ConfirmView.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol ConfirmViewDelegate: class {
  func viewDidConfirm()
}

class ConfirmView: UIView {

  @IBOutlet var tapAndHoldLabel: UILabel!
  @IBOutlet var confirmButton: ConfirmPaymentButton!

  weak var delegate: ConfirmViewDelegate?

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
  }

  var style: ConfirmPaymentButton.Style = .original {
    didSet {
      confirmButton.style = style
    }
  }

  lazy private var confirmLongPressGestureRecognizer: UILongPressGestureRecognizer =
    UILongPressGestureRecognizer(target: self, action: #selector(confirmButtonDidConfirm))

  private var feedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .clear

    feedbackGenerator.prepare()
    confirmLongPressGestureRecognizer.allowableMovement = 1000
    confirmLongPressGestureRecognizer.minimumPressDuration = confirmButton.secondsToConfirm
    confirmButton.addGestureRecognizer(confirmLongPressGestureRecognizer)

    tapAndHoldLabel.textColor = .darkGrayText
    tapAndHoldLabel.font = .medium(13)
    confirmButton.style = style
  }

  @IBAction func confirmButtonWasHeld() {
    feedbackGenerator.impactOccurred()
    confirmButton.animate()
  }

  @IBAction func confirmButtonWasReleased() {
    confirmButton.reset()
  }

  @objc func confirmButtonDidConfirm() {
    if confirmLongPressGestureRecognizer.state == .began {
      delegate?.viewDidConfirm()
    }

    confirmButton.reset()
  }
}
