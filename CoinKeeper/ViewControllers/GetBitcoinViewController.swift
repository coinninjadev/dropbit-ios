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
  func viewControllerBuyWithApplePay(_ viewController: GetBitcoinViewController, address: String)
}

final class GetBitcoinViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var findATMButton: PrimaryActionButton!
  @IBOutlet var centerStackView: UIStackView!
  @IBOutlet var purchaseBitcoinInfoLabel: UILabel!
  @IBOutlet var copyBitcoinAddressButton: LightBorderedButton!

  var buyWithApplePayButton: PKPaymentButton!

  private(set) weak var delegate: GetBitcoinViewControllerDelegate!
  private(set) var bitcoinAddress = ""

  static func newInstance(delegate: GetBitcoinViewControllerDelegate,
                          bitcoinAddress: String) -> GetBitcoinViewController {
    let vc = GetBitcoinViewController.makeFromStoryboard()
    vc.delegate = delegate
    vc.bitcoinAddress = bitcoinAddress
    if PKPaymentAuthorizationController.canMakePayments() {
      let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
      button.addTarget(vc, action: #selector(buyWithApplePay), for: .touchUpInside)
      vc.buyWithApplePayButton = button
    } else {
      let button = PKPaymentButton(paymentButtonType: .setUp, paymentButtonStyle: .black)
      button.addTarget(vc, action: #selector(setupApplePay), for: .touchUpInside)
      vc.buyWithApplePayButton = button
    }
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

  @objc func buyWithApplePay() {
    delegate.viewControllerBuyWithApplePay(self, address: bitcoinAddress)
  }

  @objc func setupApplePay() {
    PKPassLibrary().openPaymentSetup()
  }

  // MARK: private
  private func setupUI() {
    /// Purchase bitcoin label
    purchaseBitcoinInfoLabel.text = """
    When purchasing Bitcoin please be sure to use the address below to deposit it directly into
    your Bitcoin wallet.
    """.removingMultilineLineBreaks()
    purchaseBitcoinInfoLabel.textColor = .outgoingGray
    purchaseBitcoinInfoLabel.font = .regular(13)

    /// Buy with Apple Pay button
//    buyWithApplePayButton.addTarget(self, action: #selector(buyWithApplePay), for: .touchUpInside)
//    centerStackView.insertArrangedSubview(buyWithApplePayButton, at: 2)
//    buyWithApplePayButton.heightAnchor.constraint(equalToConstant: 51).isActive = true

    let mapPinImage = UIImage(imageLiteralResourceName: "mapPin")
    let font = UIFont.medium(13)
    let lightningAddressAttributes: StringAttributes = [
      .font: font,
      .foregroundColor: UIColor.darkBlueText
    ]
    let blueAttributes: StringAttributes = [
      .font: font,
      .foregroundColor: UIColor.lightGrayText
    ]

    // The font descender relates to the bottom y-coordinate, offset from the baseline, of the receiver’s longest descender.
    let atmAttributedString = NSAttributedString(
      image: mapPinImage,
      fontDescender: font.descender,
      imageSize: CGSize(width: 13, height: 20)) + "  " + NSAttributedString(string: "FIND BITCOIN ATM", attributes: blueAttributes)
    findATMButton.setAttributedTitle(atmAttributedString, for: .normal)
    findATMButton.style = .standard

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
