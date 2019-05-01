//
//  GetBitcoinCopiedAddressViewController.swift
//  DropBit
//
//  Created by Ben Winters on 5/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class GetBitcoinCopiedAddressViewController: UIViewController, StoryboardInitializable {

  @IBOutlet var semiOpaqueBackground: UIView!
  @IBOutlet var alertBackground: UIView!
  @IBOutlet var addressLabelContainer: UIView!
  @IBOutlet var addressLabel: UILabel!
  @IBOutlet var messageLabel: UILabel!
  @IBOutlet var separatorView: UIView!
  @IBOutlet var confirmationButton: UIButton!

  @IBAction func confirm(_ sender: Any) {
    delegate.viewControllerDidSelectClose(self)
  }

  private weak var delegate: ViewControllerDismissable!
  private var address = ""
  static func newInstance(address: String, delegate: ViewControllerDismissable) -> GetBitcoinCopiedAddressViewController {
    let vc = GetBitcoinCopiedAddressViewController.makeFromStoryboard()
    vc.modalPresentationStyle = .overFullScreen
    vc.modalTransitionStyle = .crossDissolve
    vc.delegate = delegate
    vc.address = address
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

    addressLabelContainer.backgroundColor = Theme.Color.whiteBackground.color
    addressLabelContainer.layer.borderColor = Theme.Color.borderDarkGray.color.cgColor
    addressLabelContainer.layer.borderWidth = 1 / UIScreen.main.nativeScale
    addressLabelContainer.setCornerRadius(4)

    addressLabel.font = Theme.Font.copiedAddress.font
    addressLabel.textColor = Theme.Color.darkBlueText.color
    addressLabel.lineBreakMode = .byTruncatingMiddle

    messageLabel.text = """
    When buying Bitcoin you will need to provide a Bitcoin address to recieve funds.
    We’ve went ahead and copied your DropBit Bitcoin address to your clipboard.
    """.removingMultilineLineBreaks()
    messageLabel.font = Theme.Font.popoverMessage.font
    messageLabel.textColor = Theme.Color.darkBlueText.color

    separatorView.backgroundColor = Theme.Color.graySeparator.color

    confirmationButton.setTitleColor(Theme.Color.lightBlueTint.color, for: .normal)
    confirmationButton.titleLabel?.font = Theme.Font.popoverActionButton.font
  }

}
