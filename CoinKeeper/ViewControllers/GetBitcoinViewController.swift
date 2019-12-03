//
//  GetBitcoinViewController.swift
//  DropBit
//
//  Created by BJ Miller on 4/10/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PassKit
import PromiseKit

protocol GetBitcoinViewControllerDelegate: URLOpener {
  func viewControllerFindBitcoinATMNearMe(_ viewController: GetBitcoinViewController)
  func viewControllerDidCopyAddress(_ viewController: UIViewController)
  func viewControllerDidPressMerchant(_ viewController: UIViewController,
                                      type: MerchantCallToActionStyle,
                                      url: URL)
}

final class GetBitcoinViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var tableView: UITableView!

  var viewModels: [MerchantResponse] = []

  private(set) weak var delegate: GetBitcoinViewControllerDelegate!
  private(set) var bitcoinAddress = ""

  static func newInstance(delegate: GetBitcoinViewControllerDelegate,
                          viewModels: [MerchantResponse],
                          bitcoinAddress: String) -> GetBitcoinViewController {
    let vc = GetBitcoinViewController.makeFromStoryboard()
    vc.delegate = delegate
    vc.viewModels = viewModels
    vc.bitcoinAddress = bitcoinAddress
    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
  }

  // MARK: private
  private func setupUI() {
    tableView.registerNib(cellType: PurchaseMerchantTableViewCell.self)
    tableView.registerNib(cellType: BitcoinAddressTableViewCell.self)

    navigationController?.setNavigationBarHidden(false, animated: true)
    navigationController?.navigationBar.tintColor = .darkBlueBackground
    let header = UILabel()
    let headerText = NSMutableAttributedString()
    headerText.appendRegular("Get Bitcoin", size: 15, color: .darkGrayBackground, paragraphStyle: nil)
    header.attributedText = headerText
    navigationItem.titleView = header

    tableView.separatorStyle = .none
    tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.backgroundColor = .lightGrayBackground
  }
}

extension GetBitcoinViewController: UITableViewDataSource, UITableViewDelegate {

  enum TableViewRows: Int {
    case bitcoinAddress = 0
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.row == TableViewRows.bitcoinAddress.rawValue {
      return 96
    } else {
      return 285
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModels.count + 1
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.row == TableViewRows.bitcoinAddress.rawValue {
      let cell: BitcoinAddressTableViewCell = tableView.dequeue(BitcoinAddressTableViewCell.self,
                                                                for: indexPath)
      cell.load(with: bitcoinAddress)
      return cell
    } else {
      let cell: PurchaseMerchantTableViewCell = tableView.dequeue(PurchaseMerchantTableViewCell.self,
                                                                  for: indexPath)

      cell.load(with: viewModels[indexPath.row - 1])
      cell.delegate = self
      return cell
    }
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard indexPath.row == TableViewRows.bitcoinAddress.rawValue else { return }

    UIPasteboard.general.string = bitcoinAddress
    delegate.viewControllerDidCopyAddress(self)
  }
}

extension GetBitcoinViewController: PurchaseMerchantTableViewCellDelegate {

  func attributeLinkWasTouched(with url: URL) {
    delegate.openURL(url, completionHandler: nil)
  }

  func tooltipButtonWasPressed(with url: URL) {
    delegate.openURL(url, completionHandler: nil)
  }

  func actionButtonWasPressed(type: MerchantCallToActionStyle, url: String) {
    guard let address = bitcoinAddress.asNilIfEmpty(),
      let url = URL(string: "\(url)?address=\(address)") else { return }

    switch type {
    case .device:
      delegate.viewControllerDidPressMerchant(self, type: type, url: url)
    case .atm:
      delegate.viewControllerFindBitcoinATMNearMe(self)
    case .default:
      UIPasteboard.general.string = bitcoinAddress
      delegate.viewControllerDidPressMerchant(self, type: type, url: url)
    }
  }
}
