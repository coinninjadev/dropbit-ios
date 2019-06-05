//
//  GetBitcoinCopiedAddressViewController.swift
//  DropBit
//
//  Created by Ben Winters on 5/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol GetBitcoinCopiedAddressViewControllerDelegate: ViewControllerDismissable, URLOpener, AuthenticationSuspendable {
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
    semiOpaqueBackground.backgroundColor = .semiOpaquePopoverBackground
    alertBackground.backgroundColor = .lightGrayBackground
    alertBackground.applyCornerRadius(9)

    bitcoinIconBackground.backgroundColor = .mango
    bitcoinIconBackground.applyCornerRadius(bitcoinIconBackground.frame.width/2)

    addressButton.backgroundColor = .whiteBackground
    addressButton.setTitleColor(.darkBlueText, for: .normal)
    addressButton.titleLabel?.font = .regular(12)
    addressButton.titleLabel?.lineBreakMode = .byTruncatingMiddle

    messageLabel.text = """
    You will need a Bitcoin address so we went ahead and
    copied your DropBit Bitcoin address to your clipboard.
    """.removingMultilineLineBreaks()
    messageLabel.font = .popoverMessage
    messageLabel.textColor = .darkBlueText

    confirmationButton.setTitle("OK, GET BITCOIN", for: .normal)
    confirmationButton.backgroundColor = .primaryActionButton
    confirmationButton.setTitleColor(.whiteText, for: .normal)
    confirmationButton.titleLabel?.font = .semiBold(14)
    confirmationButton.applyCornerRadius(4)
  }

}
