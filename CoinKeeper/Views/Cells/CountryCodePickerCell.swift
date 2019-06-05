//
//  CountryCodePickerCell.swift
//  DropBit
//
//  Created by Ben Winters on 2/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class CountryCodePickerCell: UITableViewCell {

  @IBOutlet var flagLabel: UILabel!
  @IBOutlet var countryNameLabel: UILabel!
  @IBOutlet var countryCodeLabel: UILabel!
  @IBOutlet var separatorView: UIView!

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .clear
    countryNameLabel.textAlignment = .left
    countryCodeLabel.textAlignment = .right
    countryNameLabel.textColor = .searchResultGrayText
    countryCodeLabel.textColor = .searchResultGrayText
    countryNameLabel.font = .regular(10)
    countryCodeLabel.font = .regular(10)
    separatorView.backgroundColor = .graySeparator

    self.selectionStyle = .none
  }

  func configure(withCountry country: CKCountry, flagFont: UIFont) {
    flagLabel.text = country.flag()
    flagLabel.font = flagFont
    countryNameLabel.text = country.localizedName
    countryCodeLabel.text = "+\(country.countryCode)"
  }

}
