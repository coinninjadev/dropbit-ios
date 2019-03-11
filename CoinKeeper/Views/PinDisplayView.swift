//
//  PinDisplayView.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol PinDisplayable {
  func setDigits(_ digits: String)
}

class PinDisplayView: UIView, PinDisplayable {

  public var isSecure: Bool = false {
    didSet {
      for digitView in allViews {
        digitView.isSecure = isSecure
      }
    }
  }

  @IBOutlet var digitView1: KeypadDigitView!
  @IBOutlet var digitView2: KeypadDigitView!
  @IBOutlet var digitView3: KeypadDigitView!
  @IBOutlet var digitView4: KeypadDigitView!
  @IBOutlet var digitView5: KeypadDigitView!
  @IBOutlet var digitView6: KeypadDigitView!

  private(set) var allViews: [KeypadDigitView] = []

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .clear
    allViews = [digitView1, digitView2, digitView3, digitView4, digitView5, digitView6]
  }

  // MARK: PinDisplayable

  func setDigits(_ digits: String) {
    guard (0...allViews.count) ~= digits.count else { return }
    allViews.enumerated().forEach { (index, view) in
      var digit = ""
      if index < digits.count {
        digit = "•"
        if !isSecure {
          let stringIndex = digits.index(digits.startIndex, offsetBy: index)
          let digitCharacter = digits[stringIndex]
          digit = String(digitCharacter)
        }
      }
      view.digit = digit
    }
  }
}
