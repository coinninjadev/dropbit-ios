//
//  TweetMethodViewController.swift
//  DropBit
//
//  Created by Ben Winters on 5/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol TweetMethodViewControllerDelegate: AnyObject {
  func viewControllerRequestedDropBitSendTweet(_ viewController: UIViewController)
  func viewControllerRequestedUserSendTweet(_ viewController: UIViewController)
}

class TweetMethodViewController: BaseViewController, StoryboardInitializable {

  private weak var delegate: TweetMethodViewControllerDelegate?
  private var recipient: TwitterContact!

  static func newInstance(twitterRecipient: TwitterContact,
                          delegate: TweetMethodViewControllerDelegate) -> TweetMethodViewController {
    let vc = TweetMethodViewController.makeFromStoryboard()
    vc.recipient = twitterRecipient
    vc.delegate = delegate
    return vc
  }

  @IBOutlet var avatarImageView: UIImageView!
  @IBOutlet var screenNameLabel: UILabel!
  @IBOutlet var messageLabel: UILabel!
  @IBOutlet var dropBitTweetButton: PrimaryActionButton!
  @IBOutlet var manualTweetButton: PrimaryActionButton!

  @IBAction func performDropBitTweet(_ sender: Any) {
    delegate?.viewControllerRequestedDropBitSendTweet(self)
  }

  @IBAction func performManualTweet(_ sender: Any) {
    delegate?.viewControllerRequestedUserSendTweet(self)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.configureViews(with: recipient)
  }

  private func configureViews(with recipient: TwitterContact) {
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
    messageLabel.text = """
    You’ve sent Bitcoin to \(recipient.displayHandle) on Twitter.
    You can notify the receiver with a tweet or to maintain privacy
    we can notify them with a tweet from our account.
    """.removingMultilineLineBreaks()

    dropBitTweetButton.style = .darkBlue
    manualTweetButton.style = .standard
    dropBitTweetButton.setTitle("LET DROPBIT SEND THE TWEET", for: .normal)
    manualTweetButton.setTitle("I'LL SEND THE TWEET MYSELF", for: .normal)
  }

}
