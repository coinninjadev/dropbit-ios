//
//  TransactionHistoryEmptyView.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol NoTransactionsViewDelegate: AnyObject {
  func noTransactionsViewDidSelectLearnAboutBitcoin(_ view: TransactionHistoryEmptyView)
  func noTransactionsViewDidSelectGetBitcoin(_ view: TransactionHistoryEmptyView)
  func noTransactionsViewDidSelectSpendBitcoin(_ view: TransactionHistoryEmptyView)
}

class TransactionHistoryEmptyView: UIView {

  @IBOutlet var getBitcoinButton: PrimaryActionButton! {
    didSet {
      getBitcoinButton.setAttributedTitle(attributedTitle(for: getBitcoinButton), for: .normal)
      getBitcoinButton.mode = .getBitcoin
    }
  }
  @IBOutlet var learnAboutBitcoinButton: PrimaryActionButton! {
    didSet {
      learnAboutBitcoinButton.setAttributedTitle(attributedTitle(for: learnAboutBitcoinButton), for: .normal)
      learnAboutBitcoinButton.mode = .learnBitcoin
    }
  }

  weak var delegate: NoTransactionsViewDelegate?

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initalize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initalize()
  }

  private func initalize() {
    backgroundColor = Theme.Color.lightGrayBackground.color
  }

  @IBAction func learnAboutBitcoin() {
    delegate?.noTransactionsViewDidSelectLearnAboutBitcoin(self)
  }

  @IBAction func getBitcoin() {
    delegate?.noTransactionsViewDidSelectGetBitcoin(self)
  }

  func image(for button: UIButton) -> UIImage? {
    switch button {
    case getBitcoinButton: return UIImage(imageLiteralResourceName: "getBitcoinLogo")
    case learnAboutBitcoinButton: return UIImage(imageLiteralResourceName: "learnBitcoinLogo")
    default: return nil
    }
  }

  func text(for button: UIButton) -> String {
    switch button {
    case getBitcoinButton: return "GET BITCOIN"
    case learnAboutBitcoinButton: return "LEARN BITCOIN"
    default: return ""
    }
  }

  func attributedSymbol(for button: UIButton) -> NSAttributedString {
    let textAttribute = NSTextAttachment()
    textAttribute.image = image(for: button)
    let size = CGFloat(20)
    textAttribute.bounds = CGRect(x: -0, y: (-size / (size / 4)),
                                  width: size, height: size)
    return NSAttributedString(attachment: textAttribute)
  }

  func attributedTitle(for button: UIButton) -> NSAttributedString {
    let string = text(for: button)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: Theme.Font.primaryButtonTitle.font,
      .foregroundColor: Theme.Color.verifyWordLightGray.color
    ]
    let attributedString = attributedSymbol(for: button) + " " + NSAttributedString(string: string, attributes: attributes)
    return attributedString
  }
}

class TransactionHistoryNoBalanceView: TransactionHistoryEmptyView {
  @IBOutlet var noTransactionsTitle: UILabel! {
    didSet {
      noTransactionsTitle.font = Theme.Font.noTransactionsTitle.font
      noTransactionsTitle.textColor = Theme.Color.grayText.color
      noTransactionsTitle.text = "No Bitcoin...Yet!"
    }
  }
  @IBOutlet var noTransactionsDetail: UILabel! {
    didSet {
      noTransactionsDetail.textColor = Theme.Color.grayText.color
      noTransactionsDetail.font = Theme.Font.noTransactionsDetail.font
      noTransactionsDetail.text = "All incoming and outgoing transactions will appear here."
    }
  }
}

class TransactionHistoryWithBalanceView: TransactionHistoryEmptyView {
  @IBOutlet var spendBitcoinButton: PrimaryActionButton! {
    didSet {
      spendBitcoinButton.setAttributedTitle(attributedTitle(for: spendBitcoinButton), for: .normal)
      spendBitcoinButton.mode = .spendBitcoin
    }
  }

  @IBAction func spendBitcoin() {
    delegate?.noTransactionsViewDidSelectSpendBitcoin(self)
  }

  override func text(for button: UIButton) -> String {
    switch button {
    case spendBitcoinButton: return "SPEND BITCOIN"
    default: return super.text(for: button)
    }
  }

  override func image(for button: UIButton) -> UIImage? {
    switch button {
    case spendBitcoinButton: return UIImage(imageLiteralResourceName: "spendBitcoinLogo")
    default: return super.image(for: button)
    }
  }
}
