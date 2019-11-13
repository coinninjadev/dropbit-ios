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

protocol GetBitcoinViewControllerDelegate: AnyObject {
  func viewControllerFindBitcoinATMNearMe(_ viewController: GetBitcoinViewController)
  func viewControllerDidCopyAddress(_ viewController: UIViewController)
  func viewControllerBuyWithApplePay(_ viewController: GetBitcoinViewController, url: String)
}

final class GetBitcoinViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var tableView: UITableView!
  @IBOutlet var purchaseBitcoinInfoLabel: UILabel!
  @IBOutlet var copyBitcoinAddressButton: LightBorderedButton!

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

  @IBAction func findATM() {
    delegate.viewControllerFindBitcoinATMNearMe(self)
  }

  @IBAction func copyBitcoinAddress(_ sender: Any) {
    UIPasteboard.general.string = bitcoinAddress
    delegate.viewControllerDidCopyAddress(self)
  }

  // MARK: private
  private func setupUI() {
    /// Purchase bitcoin label
    purchaseBitcoinInfoLabel.text = """
    Bitcoin purchased with Apple Pay will automatically get deposited into your Bitcoin wallet using the
    address below.
    """.removingMultilineLineBreaks()
    purchaseBitcoinInfoLabel.textColor = .outgoingGray
    purchaseBitcoinInfoLabel.font = .regular(13)

    let buyBitcoinImageString = NSAttributedString(
      image: UIImage(imageLiteralResourceName: "bitcoinOrangeB"),
      fontDescender: font.descender,
      imageSize: CGSize(width: 12, height: 17)) + "  "
    let buyBitcoinAttributedString = NSMutableAttributedString(attributedString: buyBitcoinImageString)
    buyBitcoinAttributedString.appendRegular(bitcoinAddress, size: 12, color: .darkBlueText, paragraphStyle: nil)
    copyBitcoinAddressButton.setAttributedTitle(buyBitcoinAttributedString, for: .normal)

    navigationController?.setNavigationBarHidden(false, animated: true)
    navigationController?.navigationBar.tintColor = .darkBlueBackground
    let header = UILabel()
    let headerText = NSMutableAttributedString()
    headerText.appendRegular("Get Bitcoin", size: 15, color: .darkGrayBackground, paragraphStyle: nil)
    header.attributedText = headerText
    navigationItem.titleView = header
  }
}

extension GetBitcoinViewController: PurchaseMerchantTableViewCellDelegate {

  func actionButtonWasPressed(with type: BuyMerchantBuyType, url: String) {
    switch type {
    case .device:
      delegate.viewControllerBuyWithApplePay(self, url: bitcoinAddress)
    case .atm:
      delegate.viewControllerFindBitcoinATMNearMe(self)
    case .default:

    }
  }
}
