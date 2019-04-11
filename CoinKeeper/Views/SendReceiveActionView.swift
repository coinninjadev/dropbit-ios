//
//  SendReceiveActionView.swift
//  DropBit
//
//  Created by BJ Miller on 4/2/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol SendReceiveActionViewDelegate: AnyObject {
  func actionViewDidSelectReceive(_ view: UIView)
  func actionViewDidSelectScan(_ view: UIView)
  func actionViewDidSelectSend(_ view: UIView)
}

class SendReceiveActionView: UIView {

  @IBOutlet var receiveButton: CalculatorPaymentButton!
  @IBOutlet var scanButton: UIButton!
  @IBOutlet var sendButton: CalculatorPaymentButton!
  @IBOutlet var maskedView: UIView!

  weak var actionDelegate: SendReceiveActionViewDelegate?

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  private func initialize() {
    xibSetup()

    backgroundColor = .clear

    maskedView.backgroundColor = Theme.Color.lightGrayBackground.color
  }

  @IBAction func receiveTapped(_ sender: UIButton) {
    actionDelegate?.actionViewDidSelectReceive(self)
  }

  @IBAction func scanTapped(_ sender: UIButton) {
    actionDelegate?.actionViewDidSelectScan(self)
  }

  @IBAction func sendTapped(_ sender: UIButton) {
    actionDelegate?.actionViewDidSelectSend(self)
  }
}
