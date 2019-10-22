//
//  GetBitcoinSuccessViewController.swift
//  DropBit
//
//  Created by BJ Miller on 10/22/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol GetBitcoinSuccessViewControllerDelegate: ViewControllerDismissable {
  func viewControllerRequestedTrackingBitcoinPurchase(_ viewController: GetBitcoinSuccessViewController, transferID: String)
}

final class GetBitcoinSuccessViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var transparentBackgroundView: UIView!
  @IBOutlet var bitcoinImageView: UIImageView!
  @IBOutlet var infoLabel: UILabel!
  @IBOutlet var contentView: UIView!
  @IBOutlet var trackButton: PrimaryActionButton!

  private(set) weak var delegate: GetBitcoinSuccessViewControllerDelegate!
  private(set) var transferID: String?

  static func newInstance(withDelegate delegate: GetBitcoinSuccessViewControllerDelegate,
                          transferID: String) -> GetBitcoinSuccessViewController {
    let controller = GetBitcoinSuccessViewController.makeFromStoryboard()
    controller.delegate = delegate
    controller.transferID = transferID
    return controller
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  @IBAction func trackPurchase() {
    if let transferID = self.transferID {
      delegate.viewControllerRequestedTrackingBitcoinPurchase(self, transferID: transferID)
    } else {
      delegate.viewControllerDidSelectClose(self)
    }
  }

  private func setupUI() {
    view.backgroundColor = .clear
    transparentBackgroundView.backgroundColor = .semiOpaquePopoverBackground

    contentView.applyCornerRadius(15)

    infoLabel.text = "Your payment is being processed. Please check back shortly."
    infoLabel.numberOfLines = 0
    infoLabel.textColor = .darkGrayText
    infoLabel.font = .regular(15)
    infoLabel.textAlignment = .center

    trackButton.style = .mediumPurple
    if transferID != nil {
      trackButton.setTitle("TRACK PURCHASE", for: .normal)
    } else {
      trackButton.setTitle("OK", for: .normal)
    }
  }
}
