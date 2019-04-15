//
//  GetBitcoinViewController.swift
//  DropBit
//
//  Created by BJ Miller on 4/10/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

final class GetBitcoinViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var headerLabel: UILabel!
  @IBOutlet var findATMButton: PrimaryActionButton!
  @IBOutlet var buyWithCreditCardButton: PrimaryActionButton!
  @IBOutlet var buyWithGiftCardButton: PrimaryActionButton!

  weak var urlOpener: URLOpener?

  override func viewDidLoad() {
    super.viewDidLoad()
    headerLabel.textColor = Theme.Color.grayText.color
    headerLabel.font = Theme.Font.sendingBitcoinAmount.font

    let mapPinImage = UIImage(imageLiteralResourceName: "mapPin")
    let dollarImage = UIImage(imageLiteralResourceName: "dollarSignCircle")
    let giftCardImage = UIImage(imageLiteralResourceName: "giftCard")
    let font = Theme.Font.secondaryButtonTitle.font
    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: Theme.Color.lightGrayText.color
    ]

    // The font descender relates to the bottom y-coordinate, offset from the baseline, of the receiver’s longest descender.
    let atmAttributedString = NSAttributedString(
      image: mapPinImage,
      fontDescender: font.descender,
      imageSize: CGSize(width: 13, height: 20)) + "  " + NSAttributedString(string: "FIND BITCOIN ATM", attributes: attributes)
    let creditCardAttributedString = NSAttributedString(
      image: dollarImage,
      fontDescender: font.descender,
      imageSize: CGSize(width: 22, height: 21)) + "  " + NSAttributedString(string: "WITH CREDIT CARD", attributes: attributes)
    let giftCardAttributedString = NSAttributedString(
      image: giftCardImage,
      fontDescender: font.descender + 2.0,  // for a slightly higher offset than just the font's descender
      imageSize: CGSize(width: 20, height: 13)) + "  " + NSAttributedString(string: "WITH GIFT CARD", attributes: attributes)

    findATMButton.setAttributedTitle(atmAttributedString, for: .normal)
    buyWithCreditCardButton.setAttributedTitle(creditCardAttributedString, for: .normal)
    buyWithGiftCardButton.setAttributedTitle(giftCardAttributedString, for: .normal)

    findATMButton.style = .standard
    buyWithCreditCardButton.style = .green
    buyWithGiftCardButton.style = .orange

    navigationController?.setNavigationBarHidden(false, animated: true)
    navigationController?.navigationBar.tintColor = Theme.Color.darkBlueButton.color
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setNavigationBarHidden(true, animated: true)
  }

  @IBAction func findATM() {
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .buyAtATM) else { return }
    urlOpener?.openURL(url, completionHandler: nil)
  }

  @IBAction func buyWithCreditCard() {
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .buyWithCreditCard) else { return }
    urlOpener?.openURL(url, completionHandler: nil)
  }

  @IBAction func buyWithGiftCard() {
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .buyGiftCards) else { return }
    urlOpener?.openURL(url, completionHandler: nil)
  }
}
