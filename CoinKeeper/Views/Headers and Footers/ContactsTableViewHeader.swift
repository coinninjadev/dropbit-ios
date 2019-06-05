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
      whatIsButton.setUnderlinedTitle("What is DropBit?", size: 10, color: .lightBlueTint)
    }
  }
  @IBOutlet var titleLabel: UILabel! {
    didSet {
      titleLabel.textColor = .white
      titleLabel.font = .medium(12)
      titleLabel.text = "Send \(CKStrings.dropBitWithTrademark)"
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    _backgroundView.backgroundColor = .darkBlueButton
  }

  @IBAction func whatIsButtonWasTouched() {
    delegate?.whatIsButtonWasTouched()
  }

}
