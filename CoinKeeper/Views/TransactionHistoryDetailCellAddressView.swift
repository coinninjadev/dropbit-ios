//
//  TransactionHistoryDetailCellAddressView.swift
//  DropBit
//
//  Created by BJ Miller on 6/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol TransactionHistoryDetailAddressViewDelegate: AnyObject {
  func addressViewDidSelectAddress(_ addressView: TransactionHistoryDetailCellAddressView)
}

class TransactionHistoryDetailCellAddressView: UIView {

  override var isHidden: Bool {
    didSet {
      if isHidden {
        allViews?.forEach { $0.isHidden = true }
      } else {
        allViews?.forEach { $0.isHidden = false }
        config.map { configure(with: $0) }
      }
    }
  }

  @IBOutlet var addressContainerView: UIView!
  @IBOutlet var addressTextButton: UIButton!
  @IBOutlet var addressImageButton: UIButton!
  @IBOutlet var addressStatusLabel: TransactionDetailStatusLabel!
  @IBOutlet var allViews: [UIView]!

  weak var selectionDelegate: TransactionHistoryDetailAddressViewDelegate?
  var config: AddressViewConfigurable!

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .clear
    addressStatusLabel.isHidden = true
    addressTextButton.titleLabel?.font = .medium(13)
    addressTextButton.setTitleColor(.lightBlueTint, for: .normal)
    addressTextButton.setTitleColor(.darkGrayText, for: .disabled)
  }

  @IBAction func addressButtonTapped(_ sender: UIButton) {
    guard let address = addressTextButton.title(for: .normal),
      address.isValidBitcoinAddress()
      else { return }
    selectionDelegate?.addressViewDidSelectAddress(self)
  }

  func configure(with config: AddressViewConfigurable) {
    self.config = config

    addressStatusLabel.text = config.addressStatusLabelString

    let maybeAddress = config.receiverAddress ?? config.addressProvidedToSender
    addressTextButton.setTitle(maybeAddress, for: .normal)

    let hideViews = config.shouldHideAddressViews
    addressStatusLabel.isHidden = hideViews.statusLabel
    addressContainerView.isHidden = hideViews.containerView

    addressTextButton.isEnabled = config.shouldEnableAddressTextButton
    addressImageButton.isHidden = config.shouldHideAddressImageButton
    layoutIfNeeded()
  }

}
