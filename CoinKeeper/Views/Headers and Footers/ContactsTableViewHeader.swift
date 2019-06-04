//
//  ContactsTableViewHeader.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol ContactsTableViewHeaderDelegate: class {
  func whatIsButtonWasTouched()
}

class ContactsTableViewHeader: UITableViewHeaderFooterView {

  weak var delegate: ContactsTableViewHeaderDelegate?

  @IBOutlet var _backgroundView: UIView!
  @IBOutlet var whatIsButton: UnderlinedTextButton! {
    didSet {
      whatIsButton.setUnderlinedTitle("What is DropBit?", size: 10, color: Theme.Color.lightBlueTint.color)
    }
  }
  @IBOutlet var titleLabel: UILabel! {
    didSet {
      titleLabel.textColor = .white
      titleLabel.font = CKFont.medium(12)
      titleLabel.text = "Send \(CKStrings.dropBitWithTrademark)"
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    _backgroundView.backgroundColor = Theme.Color.darkBlueButton.color
  }

  @IBAction func whatIsButtonWasTouched() {
    delegate?.whatIsButtonWasTouched()
  }

}
