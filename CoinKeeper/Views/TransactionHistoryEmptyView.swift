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
      getBitcoinButton.style = .green
    }
  }
  @IBOutlet var learnAboutBitcoinButton: PrimaryActionButton! {
    didSet {
      learnAboutBitcoinButton.setAttributedTitle(attributedTitle(for: learnAboutBitcoinButton), for: .normal)
      learnAboutBitcoinButton.style = .darkBlue
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
    backgroundColor = .lightGrayBackground
  }

  private let buttonFont: UIFont = .primaryButtonTitle

  @IBAction func learnAboutBitcoin() {
    delegate?.noTransactionsViewDidSelectLearnAboutBitcoin(self)
  }

  @IBAction func getBitcoin() {
    delegate?.noTransactionsViewDidSelectGetBitcoin(self)
  }

  func image(for button: UIButton) -> (UIImage, CGSize)? {
    switch button {
    case getBitcoinButton: return (UIImage(imageLiteralResourceName: "getBitcoinLogo"), CGSize(width: 21, height: 21))
    case learnAboutBitcoinButton: return (UIImage(imageLiteralResourceName: "learnBitcoinLogo"), CGSize(width: 22, height: 18))
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
    guard let imageData = image(for: button) else { return NSAttributedString(string: "") }
    let image = imageData.0
    let size = imageData.1
    return NSAttributedString(image: image, fontDescender: buttonFont.descender, imageSize: size) //NSAttributedString(attachment: textAttribute)
  }

  func attributedTitle(for button: UIButton) -> NSAttributedString {
    let string = text(for: button)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: buttonFont,
      .foregroundColor: UIColor.extraLightGrayText
    ]
    let attributedString = attributedSymbol(for: button) + "  " + NSAttributedString(string: string, attributes: attributes)
    return attributedString
  }
}

class TransactionHistoryNoBalanceView: TransactionHistoryEmptyView {
  @IBOutlet var noTransactionsTitle: UILabel! {
    didSet {
      noTransactionsTitle.font = .medium(20)
      noTransactionsTitle.textColor = .darkGrayText
      noTransactionsTitle.text = "No Bitcoin...Yet!"
    }
  }
  @IBOutlet var noTransactionsDetail: UILabel! {
    didSet {
      noTransactionsDetail.textColor = .darkGrayText
      noTransactionsDetail.font = .regular(15)
      noTransactionsDetail.text = "All incoming and outgoing transactions will appear here."
    }
  }
}

class TransactionHistoryWithBalanceView: TransactionHistoryEmptyView {
  @IBOutlet var spendBitcoinButton: PrimaryActionButton! {
    didSet {
      spendBitcoinButton.setAttributedTitle(attributedTitle(for: spendBitcoinButton), for: .normal)
      spendBitcoinButton.style = .orange
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

  override func image(for button: UIButton) -> (UIImage, CGSize)? {
    switch button {
    case spendBitcoinButton: return (UIImage(imageLiteralResourceName: "spendBitcoinLogo"), CGSize(width: 24, height: 17))
    default: return super.image(for: button)
    }
  }
}
