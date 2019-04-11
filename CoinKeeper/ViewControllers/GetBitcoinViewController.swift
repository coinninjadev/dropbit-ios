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


  }

//  private func attributedSymbol(for image: UIImage) -> NSAttributedString {
//    let textAttribute = NSTextAttachment()
//    textAttribute.image = image
//    let size = CGFloat(20)
//    textAttribute.bounds = CGRect(x: -0, y: (-size / (size / 4)),
//                                  width: size, height: size)
//    return NSAttributedString(attachment: textAttribute)
//  }

  @IBAction func findATM() {

  }

  @IBAction func buyWithCreditCard() {

  }

  @IBAction func buyWithGiftCard() {

  }
}
