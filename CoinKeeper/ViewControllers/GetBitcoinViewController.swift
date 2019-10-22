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
  func viewControllerBuyWithCreditCard(_ viewController: GetBitcoinViewController)
  func viewControllerBuyWithApplePay(_ viewController: GetBitcoinViewController)
}

final class GetBitcoinViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var headerLabel: UILabel!
  @IBOutlet var findATMButton: PrimaryActionButton!
  @IBOutlet var buyExternallyButton: PrimaryActionButton!
  @IBOutlet var centerStackView: UIStackView!
  @IBOutlet var purchaseBitcoinInfoLabel: UILabel!
  @IBOutlet var copyLightningAddressButton: LightBorderedButton!

//  let buyWithApplePayButton = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
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
    let networks: [PKPaymentNetwork] = [.amex, .masterCard, .visa]
    let capabilities: PKMerchantCapability = [.capabilityCredit, .capabilityDebit]
    if PKPaymentAuthorizationController.canMakePayments(usingNetworks: networks, capabilities: capabilities) {
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

  @objc func setupApplePay() {
    PKPassLibrary().openPaymentSetup()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
  }

  @IBAction func findATM() {
    delegate.viewControllerFindBitcoinATMNearMe(self)
  }

  @IBAction func buyExternally() {
    delegate.viewControllerBuyWithCreditCard(self)
  }

  @IBAction func copyLightningAddress(_ sender: Any) {
    UIPasteboard.general.string = lightningAddress
  }

  @objc func buyWithApplePay() {
    delegate.viewControllerBuyWithApplePay(self)
  }

  // MARK: private
  private func setupUI() {
    /// Header label
    headerLabel.textColor = .darkGrayText
    headerLabel.font = .light(15)

    /// Purchase bitcoin label
    purchaseBitcoinInfoLabel.text = """
    Bitcoin purchased Apple Pay will automatically get deposited into your Lightning wallet using the
    address below.
    """.removingMultilineLineBreaks()
    purchaseBitcoinInfoLabel.textColor = .mediumPurple

    /// Buy with Apple Pay button
    buyWithApplePayButton.addTarget(self, action: #selector(buyWithApplePay), for: .touchUpInside)
    centerStackView.insertArrangedSubview(buyWithApplePayButton, at: 1)
    buyWithApplePayButton.heightAnchor.constraint(equalToConstant: 51).isActive = true

    let mapPinImage = UIImage(imageLiteralResourceName: "mapPinBlue")
    let lightningFlash = UIImage(imageLiteralResourceName: "blueFlashIcon")
    let font = UIFont.medium(15)
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
//    buyExternallyButton.setAttributedTitle(lightningAddressAttributedString, for: .normal)

    findATMButton.style = .standardClear
//    buyExternallyButton.style = .green

    navigationController?.setNavigationBarHidden(false, animated: true)
    navigationController?.navigationBar.tintColor = .darkBlueBackground
  }
}
