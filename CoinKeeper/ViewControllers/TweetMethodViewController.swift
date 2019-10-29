//
//  TweetMethodViewController.swift
//  DropBit
//
//  Created by Ben Winters on 5/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

enum NotifyRecipientMethod {
  case twitterApp, shareSheet
}

protocol TweetMethodViewControllerDelegate: ViewControllerDismissable {
  func viewControllerRequestedUserSendTweet(_ viewController: UIViewController,
                                            response: WalletAddressRequestResponse,
                                            method: NotifyRecipientMethod)
}

class TweetMethodViewController: BaseViewController, StoryboardInitializable {

  private weak var delegate: TweetMethodViewControllerDelegate?
  private var recipient: TwitterContactType!
  private var addressRequestResponse: WalletAddressRequestResponse!

  static func newInstance(twitterRecipient: TwitterContactType,
                          addressRequestResponse: WalletAddressRequestResponse,
                          delegate: TweetMethodViewControllerDelegate) -> TweetMethodViewController {
    let vc = TweetMethodViewController.makeFromStoryboard()
    vc.recipient = twitterRecipient
    vc.addressRequestResponse = addressRequestResponse
    vc.delegate = delegate
    vc.modalTransitionStyle = .crossDissolve
    vc.modalPresentationStyle = .overFullScreen
    return vc
  }

  @IBOutlet var semiOpaqueBackgroundView: UIView!
  @IBOutlet var backgroundView: UIView!
  @IBOutlet var avatarImageView: UIImageView!
  @IBOutlet var screenNameLabel: UILabel!
  @IBOutlet var messageLabel: UILabel!
  @IBOutlet var twitterAppButton: PrimaryActionButton!
  @IBOutlet var shareSheetButton: UIButton!

  @IBAction func sendWithTwitterApp(_ sender: Any) {
    delegate?.viewControllerRequestedUserSendTweet(self, response: addressRequestResponse, method: .twitterApp)
  }

  @IBAction func sendWithShareSheet(_ sender: Any) {
    delegate?.viewControllerRequestedUserSendTweet(self, response: addressRequestResponse, method: .shareSheet)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .clear
    semiOpaqueBackgroundView.backgroundColor = .semiOpaquePopoverBackground
    backgroundView.applyCornerRadius(9)
    configureViews(with: recipient)
  }

  private func configureViews(with recipient: TwitterContactType) {
    avatarImageView.applyCornerRadius(avatarImageView.frame.width/2)
    if let imageData = recipient.twitterUser.profileImageData {
      avatarImageView.image = UIImage(data: imageData)
    } else {
      avatarImageView.isHidden = true
    }

    screenNameLabel.font = .medium(20)
    screenNameLabel.textColor = .darkBlueText
    screenNameLabel.text = recipient.displayHandle

    messageLabel.font = .medium(14)
    messageLabel.textColor = .darkBlueText
    messageLabel.text = messageText(with: recipient)

    twitterAppButton.style = .standard
    twitterAppButton.setTitle("SEND NOTIFICATION TWEET", for: .normal)

    shareSheetButton.backgroundColor = .clear
    shareSheetButton.setTitleColor(.darkBlueText, for: .normal)
    shareSheetButton.titleLabel?.font = .primaryButtonTitle
    shareSheetButton.setTitle("DON'T HAVE THE TWITTER APP?", for: .normal)
  }

  private func messageText(with recipient: TwitterContactType) -> String {
    return """
    You’ve sent Bitcoin to \(recipient.displayHandle) on Twitter.
    Be sure to send a notification tweet so they can claim their Bitcoin.
    """.removingMultilineLineBreaks()
  }

}
