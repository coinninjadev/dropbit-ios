//
//  ServerAddressView.swift
//  DropBit
//
//  Created by Mitch on 10/23/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol ServerAddressViewDelegate: class {
  func didPressQuestionMarkButton()
  func didPressCloseButton()
}

class ServerAddressView: UIView {
  @IBOutlet var titleLabel: UILabel! {
    didSet {
      titleLabel.text = "DropBit Addresses"
      titleLabel.font = CKFont.medium(19)
    }
  }
  @IBOutlet var tableFooterLabel: UILabel! {
    didSet {
      tableFooterLabel.textColor = Theme.Color.darkBlueText.color
      tableFooterLabel.font = CKFont.medium(12)
      tableFooterLabel.adjustsFontSizeToFitWidth = true
    }
  }
  @IBOutlet var addressTableView: UITableView!
  @IBOutlet var questionMarkButton: UIButton!
  weak var delegate: ServerAddressViewDelegate?

  var addresses: [ServerAddressViewModel] = [] {
    didSet {
      addressTableView.reloadData()
    }
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initalize()
  }

  @IBAction func questionMarkButtonWasTouched() {
    delegate?.didPressQuestionMarkButton()
  }

  @IBAction func closeButtonWasTouched() {
    delegate?.didPressCloseButton()
  }

  private func initalize() {
    xibSetup()
    backgroundColor = Theme.Color.lightGrayBackground.color
    addressTableView.delegate = self
    addressTableView.isScrollEnabled = false
    addressTableView.dataSource = self
    addressTableView.registerNib(cellType: AddressTableViewCell.self)
    addressTableView.applyCornerRadius(10)
    addressTableView.layer.borderColor = Theme.Color.borderDarkGray.color.cgColor
    addressTableView.layer.borderWidth = 0.5
    addressTableView.separatorInset = .zero

    applyCornerRadius(13)
    layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
  }
}

extension ServerAddressView: UITableViewDelegate {

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) as? AddressTableViewCell else { return }
    cell.swapShownLabel()
  }
}

extension ServerAddressView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 66
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return addresses.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: AddressTableViewCell.reuseIdentifier, for: indexPath) as? AddressTableViewCell,
      let address = addresses[safe: indexPath.row] else {
        return UITableViewCell()
    }

    cell.setServerAddress(address)

    return cell
  }

}
