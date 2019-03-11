//
//  ContactCell.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol ContactCellDelegate: class {
  func inviteButtonWasTouched(inCell cell: ContactCell)
  func sendButtonWasTouched(inCell cell: ContactCell)
}

class ContactCell: UITableViewCell {

  weak var delegate: ContactCellDelegate?

  @IBOutlet var nameLabel: UILabel!
  @IBOutlet var sendButton: UIButton!
  @IBOutlet var phoneNumberLabel: UILabel!
  @IBOutlet var inviteButton: UIButton!

  override func awakeFromNib() {
    super.awakeFromNib()
    selectionStyle = .none
    backgroundColor = Theme.Color.lightGrayBackground.color

    nameLabel.font = Theme.Font.contactTitle.font
    nameLabel.textColor = Theme.Color.darkBlueText.color
    sendButton.setTitleColor(Theme.Color.lightBlueTint.color, for: .normal)
    phoneNumberLabel.textColor = Theme.Color.grayText.color
    phoneNumberLabel.font = Theme.Font.phoneNumberDetail.font
  }

  func load(with number: CCMPhoneNumber) {
    nameLabel.text = number.cachedContact?.displayName
    phoneNumberLabel.text = number.displayNumber

    switch number.verificationStatus {
    case .notVerified:
      sendButton.isHidden = true
      inviteButton.isHidden = false
    case .verified:
      sendButton.isHidden = false
      inviteButton.isHidden = true
    }
  }

  @IBAction func sendButtonWasTouched() {
    delegate?.sendButtonWasTouched(inCell: self)
  }

  @IBAction func inviteButtonWasTouched() {
    delegate?.inviteButtonWasTouched(inCell: self)
  }
}
