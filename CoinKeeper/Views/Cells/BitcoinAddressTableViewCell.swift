//
//  BitcoinAddressTableViewCell.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class BitcoinAddressTableViewCell: UITableViewCell {

  static let bitcoinImageString: NSMutableAttributedString = {
    let buyBitcoinImageString = NSAttributedString(
      image: UIImage(imageLiteralResourceName: "bitcoinOrangeB"),
      fontDescender: UIFont.medium(18).descender,
      imageSize: CGSize(width: 12, height: 17)) + "  "
    return NSMutableAttributedString(attributedString: buyBitcoinImageString)
  }()

  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var containerView: UIView!
  @IBOutlet var bitcoinAddressLabel: PaddedLabel!

  override func awakeFromNib() {
    super.awakeFromNib()

    backgroundColor = .lightGrayBackground
    selectionStyle = .none

    titleLabel.font = .medium(16)
    titleLabel.backgroundColor = .lightGrayBackground
    titleLabel.text = "DropBit Bitcoin Receive Address"
    titleLabel.backgroundColor = .lightGrayBackground

    containerView.applyCornerRadius(10)
    containerView.layer.borderColor = UIColor.mediumGrayBorder.cgColor
    containerView.layer.borderWidth = 1

    let buyBitcoinImageString = NSAttributedString(
      image: UIImage(imageLiteralResourceName: "bitcoinOrangeB"),
      fontDescender: UIFont.medium(18).descender,
      imageSize: CGSize(width: 12, height: 17)) + "  "
    let buyBitcoinAttributedString = NSMutableAttributedString(attributedString: buyBitcoinImageString)
    bitcoinAddressLabel.attributedText = buyBitcoinAttributedString
    bitcoinAddressLabel.backgroundColor = .white
    bitcoinAddressLabel.font = .regular(15)
  }

  func load(with address: String) {
    bitcoinAddressLabel.attributedText = BitcoinAddressTableViewCell.bitcoinImageString +
      NSAttributedString(string: address)
  }
}
