//
//  GetBitcoinCopiedAddressViewController.swift
//  DropBit
//
//  Created by Ben Winters on 5/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol GetBitcoinCopiedAddressViewControllerDelegate: ViewControllerDismissable, URLOpener {
  func viewControllerDidCopyAddress(_ viewController: UIViewController)
  func viewControllerRequestedAuthenticationSuspension(_ viewController: UIViewController)
}

class GetBitcoinCopiedAddressViewController: UIViewController, StoryboardInitializable {

  @IBOutlet var semiOpaqueBackground: UIView!
  @IBOutlet var alertBackground: UIView!
  @IBOutlet var bitcoinIconBackground: UIView!
  @IBOutlet var addressButton: UIButton!

  @IBOutlet var messageLabel: UILabel!
  @IBOutlet var confirmationButton: UIButton!

  @IBAction func close(_ sender: Any) {
    delegate.viewControllerDidSelectClose(self)
  }

  @IBAction func copyAddress(_ sender: Any) {
    UIPasteboard.general.string = address
    delegate.viewControllerDidCopyAddress(self)
  }

  @IBAction func confirm(_ sender: Any) {
    delegate.viewControllerRequestedAuthenticationSuspension(self)
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
    addressButton.setTitle(address, for: .normal)
  }

  private func setupViews() {
    self.view.backgroundColor = .clear
    semiOpaqueBackground.backgroundColor = Theme.Color.semiOpaquePopoverBackground.color
    alertBackground.backgroundColor = Theme.Color.lightGrayBackground.color
    alertBackground.setCornerRadius(9)

    bitcoinIconBackground.backgroundColor = Theme.Color.mango.color
    bitcoinIconBackground.setCornerRadius(bitcoinIconBackground.frame.width/2)

    addressButton.backgroundColor = Theme.Color.whiteBackground.color
    addressButton.setTitleColor(Theme.Color.darkBlueText.color, for: .normal)
    addressButton.titleLabel?.font = Theme.Font.copiedAddress.font
    addressButton.titleLabel?.lineBreakMode = .byTruncatingMiddle

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
