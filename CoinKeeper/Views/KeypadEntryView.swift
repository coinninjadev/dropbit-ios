//
//  KeypadEntryView.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol KeypadEntryViewDelegate: AnyObject {
  func selected(digit: String)
  func selectedDecimal()
  func selectedBack()
}

extension KeypadEntryViewDelegate {
  func selectedDecimal() { }
}

@IBDesignable class KeypadEntryView: UIView {

  enum KeypadEntryMode {
    case pin, currency
  }

  weak var delegate: KeypadEntryViewDelegate?
  var entryMode: KeypadEntryMode = .pin {
    didSet {
      decimalButton?.alpha = (entryMode == .currency) ? 1 : 0
      decimalButton?.isEnabled = (entryMode == .currency)
    }
  }

  @IBOutlet var button1: KeypadButton!
  @IBOutlet var button2: KeypadButton!
  @IBOutlet var button3: KeypadButton!
  @IBOutlet var button4: KeypadButton!
  @IBOutlet var button5: KeypadButton!
  @IBOutlet var button6: KeypadButton!
  @IBOutlet var button7: KeypadButton!
  @IBOutlet var button8: KeypadButton!
  @IBOutlet var button9: KeypadButton!
  @IBOutlet var button0: KeypadButton!
  @IBOutlet var decimalButton: KeypadButton!
  @IBOutlet var backButton: KeypadButton!
  @IBOutlet var allButtons: [KeypadButton]!

  @IBInspectable var buttonColor: UIColor? = Theme.Color.primaryActionButton.color {
    didSet {
      self.tintColor = buttonColor
    }
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  private func initialize() {
    backgroundColor = .clear
    xibSetup()
    self.tintColor = buttonColor
    let separator = Locale.current.decimalSeparator ?? "."
    decimalButton.setTitle(separator, for: .normal)
  }

  @IBAction func numberButtonTapped(_ sender: KeypadButton? = nil) {
    guard let digit = sender?.title(for: .normal) else { return }
    delegate?.selected(digit: digit)
  }

  @IBAction func backButtonTapped(_ sender: KeypadButton? = nil) {
    delegate?.selectedBack()
  }

  @IBAction func decimalButtonTapped(_ sender: KeypadButton? = nil) {
    delegate?.selectedDecimal()
  }
}
