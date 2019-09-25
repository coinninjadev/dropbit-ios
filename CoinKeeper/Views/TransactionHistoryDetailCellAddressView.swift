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
        viewModel.map { load(with: $0) }
      }
    }
  }

  @IBOutlet var addressContainerView: UIView!
  @IBOutlet var addressTextButton: UIButton! {
    didSet {
      addressTextButton.titleLabel?.font = .medium(13)
    }
  }
  @IBOutlet var addressImageButton: UIButton!
  @IBOutlet var addressStatusLabel: TransactionDetailStatusLabel!
  @IBOutlet var allViews: [UIView]!

  weak var selectionDelegate: TransactionHistoryDetailAddressViewDelegate?
  var viewModel: OldTransactionDetailCellViewModel?

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
  }

  @IBAction func addressButtonTapped(_ sender: UIButton) {
    guard let address = addressTextButton.title(for: .normal),
      address.isValidBitcoinAddress()
      else { return }
    selectionDelegate?.addressViewDidSelectAddress(self)
  }

  func load(with viewModel: OldTransactionDetailCellViewModel) {
    self.viewModel = viewModel
    if let invitationStatus = viewModel.invitationStatus {
      switch invitationStatus {
      case .completed, .addressSent:
        addressContainerView.isHidden = false
        addressStatusLabel.isHidden = true
      case .canceled, .expired:
        addressContainerView.isHidden = true
        addressStatusLabel.isHidden = true
      default:
        addressContainerView.isHidden = true
        addressStatusLabel.isHidden = false
      }
    } else {
      let shouldHideAddressButton = !(viewModel.addressButtonIsActive)
      addressContainerView.isHidden = shouldHideAddressButton
      addressStatusLabel.isHidden = !shouldHideAddressButton
    }

    addressStatusLabel.text = viewModel.addressStatusLabelString

    // this should be populated with the address also, just previously hidden, now visible
    addressTextButton.setTitle(viewModel.receiverAddress, for: .normal)
    addressTextButton.setTitleColor(.lightBlueTint, for: .normal)
    addressTextButton.setTitleColor(.darkGrayText, for: .disabled)

    addressTextButton.isEnabled = !viewModel.broadcastFailed
    addressImageButton.isHidden = (viewModel.broadcastFailed || !viewModel.addressButtonIsActive)
    layoutIfNeeded()
  }

}
