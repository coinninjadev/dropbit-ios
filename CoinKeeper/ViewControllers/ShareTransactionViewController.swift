//
//  ShareTransactionViewController.swift
//  DropBit
//
//  Created by Ben Winters on 4/18/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol ViewControllerDontShowable: AnyObject {
  func viewControllerRequestedDontShowAgain(_ viewController: UIViewController)
}
protocol ShareTransactionViewControllerDelegate: ViewControllerDismissable, ViewControllerDontShowable {
  func viewControllerRequestedShareTransactionOnTwitter(_ viewController: UIViewController)
}

class ShareTransactionViewController: UIViewController, StoryboardInitializable {

  @IBOutlet var topMessageLabel: UILabel!
  @IBOutlet var bottomMessageLabel: UILabel!
  @IBOutlet var twitterButton: UIButton!
  @IBOutlet var nextTimeButton: UIButton!
  @IBOutlet var dontAskAgainButton: UIButton!
  @IBOutlet var dontAskAgainFadedBackground: UIView!

  @IBAction func performTwitter(_ sender: Any) {
    delegate?.viewControllerRequestedShareTransactionOnTwitter(self)
  }

  @IBAction func performNextTime(_ sender: Any) {
    delegate?.viewControllerDidSelectClose(self)
  }

  @IBAction func performDontAskAgain(_ sender: Any) {
    delegate?.viewControllerRequestedDontShowAgain(self)
  }

  weak var delegate: ShareTransactionViewControllerDelegate?

  static func newInstance(delegate: ShareTransactionViewControllerDelegate) -> ShareTransactionViewController {
    let vc = ShareTransactionViewController.makeFromStoryboard()
    vc.delegate = delegate
    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    configureView()
  }

  private func configureView() {
    topMessageLabel.textColor = Theme.Color.lightGrayText.color
    topMessageLabel.font = Theme.Font.shareTransactionMessage.font

    bottomMessageLabel.textColor = Theme.Color.darkBlueText.color
    bottomMessageLabel.font = Theme.Font.shareTransactionMessage.font

    twitterButton.backgroundColor = Theme.Color.primaryActionButton.color
    twitterButton.layer.masksToBounds = true
    twitterButton.layer.cornerRadius = 4

    nextTimeButton.titleLabel?.font = Theme.Font.primaryButtonTitle.font
    nextTimeButton.setTitleColor(Theme.Color.darkBlueText.color, for: .normal)

    // semi-opaque view sits between the button and the separate backing view
    // so that title and background have correct color
    dontAskAgainButton.titleLabel?.font = Theme.Font.primaryButtonTitle.font
    dontAskAgainButton.setTitleColor(Theme.Color.grayText.color, for: .normal)
    dontAskAgainFadedBackground.backgroundColor = Theme.Color.primaryActionButton.color
    dontAskAgainFadedBackground.layer.masksToBounds = true
    dontAskAgainFadedBackground.layer.cornerRadius = 4
  }

}
