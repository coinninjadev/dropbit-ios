//
//  AddressTableViewCell.swift
//  DropBit
//
//  Created by Mitch on 10/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class AddressTableViewCell: UITableViewCell {
  @IBOutlet var addressLabel: UILabel! {
    didSet {
      addressLabel.textColor = Theme.Color.grayText.color
      addressLabel.font = Theme.Font.serverAddress.font
      addressLabel.adjustsFontSizeToFitWidth = true
    }
  }

  @IBOutlet var derivationPathLabel: UILabel! {
    didSet {
      derivationPathLabel.textColor = Theme.Color.darkBlueText.color
      derivationPathLabel.font = Theme.Font.serverAddress.font
    }
  }

  func setServerAddress(_ serverAddress: ServerAddressViewModel) {
    addressLabel.text = serverAddress.address
    derivationPathLabel.text = serverAddress.derivationString
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    selectionStyle = .none
    backgroundColor = Theme.Color.lightGrayBackground.color
    derivationPathLabel.isHidden = true
  }

  func swapShownLabel() {
    derivationPathLabel.isHidden = !derivationPathLabel.isHidden
    addressLabel.isHidden = !addressLabel.isHidden
  }
}
