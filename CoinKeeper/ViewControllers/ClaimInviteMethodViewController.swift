//
//  ClaimInviteMethodViewController.swift
//  DropBit
//
//  Created by Ben Winters on 5/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol ClaimInviteMethodViewControllerDelegate: AnyObject {
  func viewControllerDidSelectClaimInvite(using method: UserIdentityType, viewController: UIViewController)
}

class ClaimInviteMethodViewController: BaseViewController, StoryboardInitializable {

  private weak var delegate: ClaimInviteMethodViewControllerDelegate?

  static func newInstance(delegate: ClaimInviteMethodViewControllerDelegate) -> ClaimInviteMethodViewController {
    let vc = ClaimInviteMethodViewController.makeFromStoryboard()
    vc.delegate = delegate
    return vc
  }

  @IBOutlet var messageLabel: UILabel!
  @IBOutlet var twitterButton: PrimaryActionButton!
  @IBOutlet var smsButton: PrimaryActionButton!

  @IBAction func performTwitter(_ sender: Any) {
    delegate?.viewControllerDidSelectClaimInvite(using: .twitter, viewController: self)
  }

  @IBAction func performSMS(_ sender: Any) {
    delegate?.viewControllerDidSelectClaimInvite(using: .phone, viewController: self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    messageLabel.text = "How were you sent Bitcoin?"
    messageLabel.font = Theme.Font.onboardingSubtitle.font
    messageLabel.textColor = Theme.Color.grayText.color
    configureButtons()
  }

  private func configureButtons() {
    twitterButton.style = .standard
    smsButton.style = .darkBlue

    let twitterTitle = NSAttributedString(imageName: "twitterBird",
                                          imageSize: CGSize(width: 20, height: 17),
                                          title: "I GOT A TWEET",
                                          sharedColor: Theme.Color.lightGrayText.color,
                                          font: Theme.Font.primaryButtonTitle.font)
    twitterButton.setAttributedTitle(twitterTitle, for: .normal)

    let smsTitle = NSAttributedString(imageName: "claimInviteSMS",
                                      imageSize: CGSize(width: 13, height: 23),
                                      title: "I GOT AN SMS",
                                      sharedColor: Theme.Color.lightGrayText.color,
                                      font: Theme.Font.primaryButtonTitle.font,
                                      imageOffset: CGPoint(x: 0, y: -3))
    smsButton.setAttributedTitle(smsTitle, for: .normal)
  }

}
