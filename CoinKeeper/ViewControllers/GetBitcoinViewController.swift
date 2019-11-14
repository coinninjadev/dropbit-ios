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
  func viewControllerBuyWithApplePay(_ viewController: GetBitcoinViewController, bitcoinAddress: String)
}

final class GetBitcoinViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var tableView: UITableView!

  var viewModels: [BuyMerchantResponse] = []

  private(set) weak var delegate: GetBitcoinViewControllerDelegate!
  private(set) var bitcoinAddress = ""

  static func newInstance(delegate: GetBitcoinViewControllerDelegate,
                          bitcoinAddress: String) -> GetBitcoinViewController {
    let vc = GetBitcoinViewController.makeFromStoryboard()
    vc.delegate = delegate
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

    setupDataSource()
  }

  private func setupDataSource() {
    var wyreAttributes: [BuyMerchantAttribute] = [], coinNinjaAttributes: [BuyMerchantAttribute] = []

    wyreAttributes.append(BuyMerchantAttribute(type: BuyMerchantAttributeType.positive,
                                               description: "Buy Bitcoin using Apple Pay",
                                               link: nil))
    wyreAttributes.append(BuyMerchantAttribute(type: BuyMerchantAttributeType.positive,
                                               description: "Takes less than 30 seconds",
                                               link: nil))
    wyreAttributes.append(BuyMerchantAttribute(type: BuyMerchantAttributeType.negative,
                                               description: "$500 daily limit",
                                               link: nil))
    wyreAttributes.append(BuyMerchantAttribute(type: BuyMerchantAttributeType.negative,
                                               description: "Location restrictions may apply",
                                               link: "https://support.sendwyre.com/en/articles/1863574-geographic-restrictions"))

    let wyre = BuyMerchantResponse(image: UIImage(imageLiteralResourceName: "wyreLogo"),
                                   tooltipUrl: "https://dropbit.app/tooltips/wyre",
                                   attributes: wyreAttributes,
                                   actionType: BuyMerchantBuyType.device.rawValue,
                                   actionUrl: "")

    coinNinjaAttributes.append(BuyMerchantAttribute(type: BuyMerchantAttributeType.positive,
                                               description: "Can use cash to buy",
                                               link: nil))
    coinNinjaAttributes.append(BuyMerchantAttribute(type: BuyMerchantAttributeType.positive,
                                               description: "Can sell Bitcoin for cash",
                                               link: nil))
    coinNinjaAttributes.append(BuyMerchantAttribute(type: BuyMerchantAttributeType.negative,
                                               description: "May limit based on verification",
                                               link: nil))
    coinNinjaAttributes.append(BuyMerchantAttribute(type: BuyMerchantAttributeType.negative,
                                               description: "High fees",
                                               link: nil))

    let coinNinja = BuyMerchantResponse(image: UIImage(imageLiteralResourceName: "coinNinjaLogo"),
                                        tooltipUrl: nil,
                                        attributes: coinNinjaAttributes,
                                        actionType: BuyMerchantBuyType.atm.rawValue,
                                        actionUrl: "")

    viewModels = [wyre, coinNinja]
  }
}

extension GetBitcoinViewController: UITableViewDataSource, UITableViewDelegate {

  enum TableViewRows: Int {
    case bitcoinAddress = 0
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
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

  func actionButtonWasPressed(with type: BuyMerchantBuyType, url: String) {
    switch type {
    case .device:
      delegate.viewControllerBuyWithApplePay(self, bitcoinAddress: bitcoinAddress)
    case .atm:
      delegate.viewControllerFindBitcoinATMNearMe(self)
    case .default:
      guard let url = URL(string: url) else { return }
      UIPasteboard.general.string = bitcoinAddress
      delegate.openURLExternally(url, completionHandler: nil)
    }
  }
}
