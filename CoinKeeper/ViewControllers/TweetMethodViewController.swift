//
//  TweetMethodViewController.swift
//  DropBit
//
//  Created by Ben Winters on 5/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

typealias TweetCompletionHandler = (_ tweetId: String?) -> Void

protocol TweetMethodViewControllerDelegate: ViewControllerDismissable {
  func viewControllerRequestedDropBitSendTweet(_ viewController: UIViewController,
                                               response: WalletAddressRequestResponse,
                                               tweetCompletion: @escaping TweetCompletionHandler)
  func viewControllerRequestedUserSendTweet(_ viewController: UIViewController,
                                            response: WalletAddressRequestResponse)
}

class TweetMethodViewController: BaseViewController, StoryboardInitializable {

  private weak var delegate: TweetMethodViewControllerDelegate?
  private var recipient: TwitterContactType!
  private var addressRequestResponse: WalletAddressRequestResponse!
  private var tweetCompletion: TweetCompletionHandler!
  private var receiverNotifiedRecently = false // Twitter and our server limit how often we can tweet at each user

  static func newInstance(twitterRecipient: TwitterContactType,
                          addressRequestResponse: WalletAddressRequestResponse,
                          tweetCompletion: @escaping TweetCompletionHandler,
                          delegate: TweetMethodViewControllerDelegate) -> TweetMethodViewController {
    let vc = TweetMethodViewController.makeFromStoryboard()
    vc.recipient = twitterRecipient
    vc.addressRequestResponse = addressRequestResponse
    vc.receiverNotifiedRecently = addressRequestResponse.notificationWasDuplicate
    vc.tweetCompletion = tweetCompletion
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
  @IBOutlet var dropBitTweetButton: PrimaryActionButton!
  @IBOutlet var manualTweetButton: PrimaryActionButton!

  @IBAction func performDropBitTweet(_ sender: Any) {
    if receiverNotifiedRecently {
      delegate?.viewControllerDidSelectClose(self)
    } else {
      delegate?.viewControllerRequestedDropBitSendTweet(
        self,
        response: addressRequestResponse,
        tweetCompletion: tweetCompletion
      )
    }
  }

  @IBAction func performManualTweet(_ sender: Any) {
    delegate?.viewControllerRequestedUserSendTweet(self, response: addressRequestResponse)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .clear
    semiOpaqueBackgroundView.backgroundColor = Theme.Color.semiOpaquePopoverBackground.color
    backgroundView.applyCornerRadius(9)
    self.configureViews(with: recipient)
  }

  private func configureViews(with recipient: TwitterContactType) {
    avatarImageView.applyCornerRadius(avatarImageView.frame.width/2)
    if let imageData = recipient.twitterUser.profileImageData {
      avatarImageView.image = UIImage(data: imageData)
    } else {
      avatarImageView.isHidden = true
    }

    screenNameLabel.font = Theme.Font.tweetMethodRecipient.font
    screenNameLabel.textColor = Theme.Color.darkBlueText.color
    screenNameLabel.text = recipient.displayHandle

    messageLabel.font = Theme.Font.tweetMethodMessage.font
    messageLabel.textColor = Theme.Color.darkBlueText.color
    messageLabel.text = messageText(with: recipient)

    dropBitTweetButton.style = .darkBlue
    manualTweetButton.style = .standard
    dropBitTweetButton.setTitle(dropBitTweetButtonTitle, for: .normal)
    manualTweetButton.setTitle(manualTweetButtonTitle, for: .normal)
  }

  private func messageText(with recipient: TwitterContactType) -> String {
    let start = "You’ve sent Bitcoin to \(recipient.displayHandle) on Twitter"
    if receiverNotifiedRecently {
      return "\(start) and they have been invited to DropBit. You can remind them with a tweet."
    } else {
      return """
        \(start). You can notify the receiver with a tweet or to maintain privacy
        we can notify them with a tweet from our account.
        """.removingMultilineLineBreaks()
    }
  }

  private var dropBitTweetButtonTitle: String {
    if receiverNotifiedRecently {
      return "OK"
    } else {
      return "LET DROPBIT SEND THE TWEET"
    }
  }

  private var manualTweetButtonTitle: String {
    if receiverNotifiedRecently {
      return "I'LL SEND A TWEET"
    } else {
      return "I'LL SEND THE TWEET MYSELF"
    }
  }

}
