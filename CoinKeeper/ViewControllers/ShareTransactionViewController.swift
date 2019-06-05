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
  func viewControllerRequestedShareNextTime(_ viewController: UIViewController)
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
    delegate?.viewControllerRequestedShareNextTime(self)
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
    topMessageLabel.textColor = .lightGrayText
    topMessageLabel.font = .medium(17)

    bottomMessageLabel.textColor = .darkBlueText
    bottomMessageLabel.font = .medium(17)

    configureTwitterButton()

    nextTimeButton.titleLabel?.font = .primaryButtonTitle
    nextTimeButton.setTitleColor(.darkBlueText, for: .normal)

    // semi-opaque view sits between the button and the separate backing view
    // so that title and background have correct color
    dontAskAgainButton.titleLabel?.font = .primaryButtonTitle
    dontAskAgainButton.setTitleColor(.grayText, for: .normal)
    dontAskAgainFadedBackground.backgroundColor = .primaryActionButton
    dontAskAgainFadedBackground.applyCornerRadius(4)
  }

  private func configureTwitterButton() {
    let font = UIFont.compactButtonTitle
    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: UIColor.whiteText
    ]

    let birdImage = UIImage(imageLiteralResourceName: "twitterBird")
    let attributedBird = NSAttributedString(image: birdImage,
                                            fontDescender: font.descender,
                                            imageSize: CGSize(width: 20, height: 16))
    let attributedTwitter = NSAttributedString(string: "  TWITTER", attributes: attributes)
    let attributedTitle = attributedBird + attributedTwitter

    twitterButton.setAttributedTitle(attributedTitle, for: .normal)
    twitterButton.backgroundColor = .primaryActionButton
    twitterButton.applyCornerRadius(4)
  }

}
