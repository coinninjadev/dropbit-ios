//
//  GetBitcoinCopiedAddressViewController.swift
//  DropBit
//
//  Created by Ben Winters on 5/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

typealias GetBitcoinCopiedAddressViewControllerDelegate = ViewControllerDismissable & URLOpener

class GetBitcoinCopiedAddressViewController: UIViewController, StoryboardInitializable {

  @IBOutlet var semiOpaqueBackground: UIView!
  @IBOutlet var alertBackground: UIView!
  @IBOutlet var bitcoinIconBackground: UIView!
  @IBOutlet var addressLabelContainer: UIView!
  @IBOutlet var addressLabel: UILabel!
  @IBOutlet var messageLabel: UILabel!
  @IBOutlet var confirmationButton: UIButton!

  @IBAction func close(_ sender: Any) {
    delegate.viewControllerDidSelectClose(self)
  }

  @IBAction func confirm(_ sender: Any) {
    // TODO: suspend authentication on open for 15 minutes
    delegate.openURLExternally(destinationURL, completionHandler: nil)
  }

  private var address = ""
  private var destinationURL: URL!
  private weak var delegate: GetBitcoinCopiedAddressViewControllerDelegate!

  static func newInstance(address: String,
                          destinationURL: URL,
                          delegate: GetBitcoinCopiedAddressViewControllerDelegate) -> GetBitcoinCopiedAddressViewController {
    let vc = GetBitcoinCopiedAddressViewController.makeFromStoryboard()
    vc.modalPresentationStyle = .overFullScreen
    vc.modalTransitionStyle = .crossDissolve
    vc.address = address
    vc.destinationURL = destinationURL
    vc.delegate = delegate
    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupViews()
    addressLabel.text = address
  }

  private func setupViews() {
    self.view.backgroundColor = .clear
    semiOpaqueBackground.backgroundColor = Theme.Color.semiOpaquePopoverBackground.color
    alertBackground.backgroundColor = Theme.Color.lightGrayBackground.color
    alertBackground.setCornerRadius(9)

    bitcoinIconBackground.backgroundColor = Theme.Color.mango.color
    bitcoinIconBackground.setCornerRadius(bitcoinIconBackground.frame.width/2)

    addressLabelContainer.backgroundColor = Theme.Color.whiteBackground.color
    addressLabelContainer.layer.borderColor = Theme.Color.borderDarkGray.color.cgColor
    addressLabelContainer.layer.borderWidth = 1 / UIScreen.main.nativeScale
    addressLabelContainer.setCornerRadius(4)

    addressLabel.font = Theme.Font.copiedAddress.font
    addressLabel.textColor = Theme.Color.darkBlueText.color
    addressLabel.lineBreakMode = .byTruncatingMiddle

    messageLabel.text = """
    You will need a Bitcoin address so we went ahead and
    copied your DropBit Bitcoin address to your clipboard.
    """.removingMultilineLineBreaks()
    messageLabel.font = Theme.Font.popoverMessage.font
    messageLabel.textColor = Theme.Color.darkBlueText.color

    confirmationButton.setTitle("OK, GET BITCOIN", for: .normal)
    confirmationButton.backgroundColor = Theme.Color.primaryActionButton.color
    confirmationButton.setTitleColor(Theme.Color.whiteText.color, for: .normal)
    confirmationButton.titleLabel?.font = Theme.Font.popoverActionButton.font
    confirmationButton.setCornerRadius(4)
  }

}
