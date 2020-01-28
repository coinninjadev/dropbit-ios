//
//  TweetMethodViewController.swift
//  DropBit
//
//  Created by Ben Winters on 5/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

enum NotifyRecipientMethod {
  case twitterApp, shareSheet, coinNinja
}

protocol TweetMethodViewControllerDelegate: ViewControllerDismissable {
  func viewControllerRequestedUserSendTweet(_ viewController: UIViewController,
                                            response: WalletAddressRequestResponse,
                                            method: NotifyRecipientMethod)
}

class TweetMethodViewController: BaseViewController, StoryboardInitializable {

  private weak var delegate: TweetMethodViewControllerDelegate?
  private var viewModel: TweetMethodViewModelType!
  private var addressRequestResponse: WalletAddressRequestResponse!

  static func newInstance(addressRequestResponse: WalletAddressRequestResponse,
                          viewModel: TweetMethodViewModelType,
                          delegate: TweetMethodViewControllerDelegate) -> TweetMethodViewController {
    let vc = TweetMethodViewController.makeFromStoryboard()
    vc.addressRequestResponse = addressRequestResponse
    vc.viewModel = viewModel
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
  @IBOutlet var firstMethodButton: PrimaryActionButton!
  @IBOutlet var secondMethodButton: PrimaryActionButton!

  @IBAction func sendWithFirstMethod(_ sender: Any) {
    let method = viewModel.firstOption.method
    delegate?.viewControllerRequestedUserSendTweet(self, response: addressRequestResponse, method: method)
  }

  @IBAction func sendWithSecondMethod(_ sender: Any) {
    let method = viewModel.secondOption.method
    delegate?.viewControllerRequestedUserSendTweet(self, response: addressRequestResponse, method: method)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .clear
    semiOpaqueBackgroundView.backgroundColor = .semiOpaquePopoverBackground
    backgroundView.applyCornerRadius(9)
    configureViews()
  }

  private func configureViews() {
    avatarImageView.applyCornerRadius(avatarImageView.frame.width/2)
    if let imageData = viewModel.recipient.twitterUser.profileImageData {
      avatarImageView.image = UIImage(data: imageData)
    } else {
      avatarImageView.isHidden = true
    }

    screenNameLabel.font = .medium(20)
    screenNameLabel.textColor = .darkBlueText
    screenNameLabel.text = viewModel.recipient.displayHandle

    messageLabel.font = .medium(14)
    messageLabel.textColor = .darkBlueText
    messageLabel.text = viewModel.message

    firstMethodButton.style = viewModel.firstOption.buttonStyle
    firstMethodButton.setTitle(viewModel.firstOption.buttonTitle, for: .normal)

    secondMethodButton.style = viewModel.secondOption.buttonStyle
    secondMethodButton.setTitle(viewModel.secondOption.buttonTitle, for: .normal)
  }

}

struct TweetMethodOption {
  let method: NotifyRecipientMethod
  let buttonTitle: String
  let buttonStyle: PrimaryActionButtonStyle
}

protocol TweetMethodViewModelType {
  var recipient: TwitterContactType { get }
  var message: String { get }
  var firstOption: TweetMethodOption { get }
  var secondOption: TweetMethodOption { get }
}

struct ServerCanTweetViewModel: TweetMethodViewModelType {

  let recipient: TwitterContactType

  var message: String {
    return """
    You’ve sent Bitcoin to \(recipient.displayHandle) on Twitter.
    You can notify the receiver with a tweet or to maintain privacy
    we can notify them with a tweet from our account.
    """.removingMultilineLineBreaks()
  }

  var firstOption: TweetMethodOption {
    TweetMethodOption(method: .coinNinja, buttonTitle: "LET DROPBIT SEND THE TWEET", buttonStyle: .darkBlue)
  }

  var secondOption: TweetMethodOption {
    TweetMethodOption(method: .twitterApp, buttonTitle: "I'LL SEND THE TWEET MYSELF", buttonStyle: .standard)
  }

}

struct ServerCannotTweetViewModel: TweetMethodViewModelType {

  let recipient: TwitterContactType

  var message: String {
    return """
    You’ve sent Bitcoin to \(recipient.displayHandle) on Twitter.
    Be sure to send a notification tweet so they can claim their Bitcoin.
    """.removingMultilineLineBreaks()
  }

  var firstOption: TweetMethodOption {
    TweetMethodOption(method: .twitterApp, buttonTitle: "SEND NOTIFICATION TWEET", buttonStyle: .standard)
  }

  var secondOption: TweetMethodOption {
    TweetMethodOption(method: .shareSheet, buttonTitle: "DON'T HAVE THE TWITTER APP?", buttonStyle: .darkBlueClear)
  }

}
