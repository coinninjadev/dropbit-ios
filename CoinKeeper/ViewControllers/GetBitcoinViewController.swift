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
    let attributes: [NSAttributedString.Key: Any] = [
      .font: Theme.Font.secondaryButtonTitle.font,
      .foregroundColor: Theme.Color.lightGrayText.color
    ]
    let atmAttributedString = attributedSymbol(for: mapPinImage) + " " + NSAttributedString(string: "FIND BITCOIN ATM", attributes: attributes)
    let creditCardAttributedString = attributedSymbol(for: dollarImage) + " " + NSAttributedString(string: "WITH CREDIT CARD", attributes: attributes)
    let giftCardAttributedString = attributedSymbol(for: giftCardImage) + " " + NSAttributedString(string: "WITH GIFT CARD", attributes: attributes)

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

  private func attributedSymbol(for image: UIImage) -> NSAttributedString {
    let textAttribute = NSTextAttachment()
    textAttribute.image = image
    let size = CGFloat(20)
    textAttribute.bounds = CGRect(x: -0, y: (-size / (size / 4)),
                                  width: size, height: size)
    return NSAttributedString(attachment: textAttribute)
  }

  @IBAction func findATM() {
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .atm) else { return }
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
