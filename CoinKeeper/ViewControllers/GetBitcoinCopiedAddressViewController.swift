//
//  GetBitcoinCopiedAddressViewController.swift
//  DropBit
//
//  Created by Ben Winters on 5/1/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class GetBitcoinCopiedAddressViewController: UIViewController, StoryboardInitializable, ViewControllerDismissable {

  @IBOutlet var semiOpaqueBackground: UIView!
  @IBOutlet var alertBackground: UIView!
  @IBOutlet var addressLabelContainer: UIView!
  @IBOutlet var addressLabel: UILabel!
  @IBOutlet var messageLabel: UILabel!
  @IBOutlet var separatorView: UIView!
  @IBOutlet var confirmationButton: UIButton!

  private weak var delegate: ViewControllerDismissable!
  private var address = ""
  static func newInstance(address: String, delegate: ViewControllerDismissable) -> GetBitcoinCopiedAddressViewController {
    let vc = GetBitcoinCopiedAddressViewController.makeFromStoryboard()
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
    alertBackground
  }



}
