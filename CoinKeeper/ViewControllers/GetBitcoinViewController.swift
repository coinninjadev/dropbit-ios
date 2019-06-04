//
//  GetBitcoinViewController.swift
//  DropBit
//
//  Created by BJ Miller on 4/10/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol GetBitcoinViewControllerDelegate: AnyObject {
  func viewControllerFindBitcoinATMNearMe(_ viewController: GetBitcoinViewController)
  func viewControllerBuyWithCreditCard(_ viewController: GetBitcoinViewController)
  func viewControllerBuyWithGiftCard(_ viewController: GetBitcoinViewController)
}

final class GetBitcoinViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var headerLabel: UILabel!
  @IBOutlet var findATMButton: PrimaryActionButton!
  @IBOutlet var buyWithCreditCardButton: PrimaryActionButton!
  @IBOutlet var buyWithGiftCardButton: PrimaryActionButton!

  var coordinationDelegate: GetBitcoinViewControllerDelegate? {
    return generalCoordinationDelegate as? GetBitcoinViewControllerDelegate
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    headerLabel.textColor = Theme.Color.grayText.color
    headerLabel.font = CKFont.light(15)

    let mapPinImage = UIImage(imageLiteralResourceName: "mapPin")
    let dollarImage = UIImage(imageLiteralResourceName: "dollarSignCircle")
    let giftCardImage = UIImage(imageLiteralResourceName: "giftCard")
    let font = CKFont.secondaryButtonTitle
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

  @IBAction func findATM() {
    coordinationDelegate?.viewControllerFindBitcoinATMNearMe(self)
  }

  @IBAction func buyWithCreditCard() {
    coordinationDelegate?.viewControllerBuyWithCreditCard(self)
  }

  @IBAction func buyWithGiftCard() {
    coordinationDelegate?.viewControllerBuyWithGiftCard(self)
  }
}
