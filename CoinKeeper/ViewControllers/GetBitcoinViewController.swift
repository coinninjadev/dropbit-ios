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
  func viewControllerBuyBitcoinExternally(_ viewController: GetBitcoinViewController)
  func viewControllerDidCopyAddress(_ viewController: UIViewController)
  func viewControllerBuyWithApplePay(_ viewController: GetBitcoinViewController, address: String)
}

final class GetBitcoinViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var findATMButton: PrimaryActionButton!
  @IBOutlet var buyExternallyButton: LightBorderedButton!
  @IBOutlet var centerStackView: UIStackView!
  @IBOutlet var purchaseBitcoinInfoLabel: UILabel!
  @IBOutlet var copyLightningAddressButton: LightBorderedButton!
  @IBOutlet var lineSeparatorView: UIView!
  @IBOutlet var buyExternallyInfoLabel: UILabel!

  var buyWithApplePayButton: PKPaymentButton!

  private(set) weak var delegate: GetBitcoinViewControllerDelegate!
  private(set) var lightningAddress = ""
  private(set) var bitcoinAddress = ""

  static func newInstance(delegate: GetBitcoinViewControllerDelegate,
                          lightningAddress: String,
                          bitcoinAddress: String) -> GetBitcoinViewController {
    let vc = GetBitcoinViewController.makeFromStoryboard()
    vc.delegate = delegate
    vc.lightningAddress = lightningAddress
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

  @IBAction func buyExternally() {
    UIPasteboard.general.string = bitcoinAddress
    delegate.viewControllerBuyBitcoinExternally(self)
  }

  @IBAction func copyLightningAddress(_ sender: Any) {
    UIPasteboard.general.string = lightningAddress
    delegate.viewControllerDidCopyAddress(self)
  }

  @objc func buyWithApplePay() {
    delegate.viewControllerBuyWithApplePay(self, address: lightningAddress)
  }

  @objc func setupApplePay() {
    PKPassLibrary().openPaymentSetup()
  }

  // MARK: private
  private func setupUI() {
    /// Purchase bitcoin label
    purchaseBitcoinInfoLabel.text = """
    Bitcoin purchased Apple Pay will automatically get deposited into your Lightning wallet using the
    address below.
    """.removingMultilineLineBreaks()
    purchaseBitcoinInfoLabel.textColor = .mediumPurple
    purchaseBitcoinInfoLabel.font = .regular(13)

    /// Buy with Apple Pay button
    buyWithApplePayButton.addTarget(self, action: #selector(buyWithApplePay), for: .touchUpInside)
    centerStackView.insertArrangedSubview(buyWithApplePayButton, at: 1)
    buyWithApplePayButton.heightAnchor.constraint(equalToConstant: 51).isActive = true

    /// Separator view
    lineSeparatorView.backgroundColor = .mediumGrayBackground

    /// BuyExternallyInfoLabel
    let attributedInfoLabel = NSMutableAttributedString()
    let boldText = "Buying Bitcoin elsewhere? "
    let mediumText = "Use the address below to deposit into your Bitcoin wallet."
    attributedInfoLabel.appendBold(boldText, size: 12, color: .darkGrayText, paragraphStyle: nil)
    attributedInfoLabel.appendMedium(mediumText, size: 12, color: .darkGrayText, paragraphStyle: nil)
    buyExternallyInfoLabel.attributedText = attributedInfoLabel

    let mapPinImage = UIImage(imageLiteralResourceName: "mapPinBlue")
    let lightningFlash = UIImage(imageLiteralResourceName: "blueFlashIcon")
    let font = UIFont.medium(13)
    let lightningAddressAttributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: UIColor.darkBlueText
    ]
    let blueAttributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: UIColor.primaryActionButton
    ]

    // The font descender relates to the bottom y-coordinate, offset from the baseline, of the receiver’s longest descender.
    let lightningAddressAttributedString = NSAttributedString(
      image: lightningFlash,
      fontDescender: font.descender,
      imageSize: CGSize(width: 14, height: 20)) + "  " + NSAttributedString(string: lightningAddress, attributes: lightningAddressAttributes)
    copyLightningAddressButton.setAttributedTitle(lightningAddressAttributedString, for: .normal)

    let atmAttributedString = NSAttributedString(
      image: mapPinImage,
      fontDescender: font.descender,
      imageSize: CGSize(width: 13, height: 20)) + "  " + NSAttributedString(string: "FIND BITCOIN ATM", attributes: blueAttributes)
    findATMButton.setAttributedTitle(atmAttributedString, for: .normal)
    findATMButton.style = .standardClear

    let buyExternallyImageString = NSAttributedString(
      image: UIImage(imageLiteralResourceName: "bitcoinOrangeB"),
      fontDescender: font.descender,
      imageSize: CGSize(width: 12, height: 17)) + "  "
    let buyExternallyAttributedString = NSMutableAttributedString(attributedString: buyExternallyImageString)
    buyExternallyAttributedString.appendRegular(bitcoinAddress, size: 12, color: .darkBlueText, paragraphStyle: nil)
    buyExternallyButton.setAttributedTitle(buyExternallyAttributedString, for: .normal)

    navigationController?.setNavigationBarHidden(false, animated: true)
    navigationController?.navigationBar.tintColor = .darkBlueBackground
    let header = UILabel()
    let headerText = NSMutableAttributedString()
    headerText.appendRegular("Get Bitcoin", size: 15, color: .darkGrayBackground, paragraphStyle: nil)
    header.attributedText = headerText
    navigationItem.titleView = header
  }
}
