//
//  PhoneNumberEntryView.swift
//  DropBit
//
//  Created by Ben Winters on 2/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PhoneNumberKit

protocol PhoneNumberEntryViewDelegate: AnyObject {
  func phoneNumberEntryViewDidTapCountryCodeButton(_ entryView: PhoneNumberEntryView)
}

class PhoneNumberEntryView: UIView {

  static let defaultRegion = Locale.current.regionCode ?? "US"
  var selectedRegion: String = PhoneNumberEntryView.defaultRegion

  static let flagFont = UIFont.systemFont(ofSize: 22)

  weak var delegate: PhoneNumberEntryViewDelegate?

  private let emojiFactory = FlagEmojiFactory()

  @IBOutlet var countryCodeButton: UIButton!
  @IBOutlet var buttonSeparator: UIView!
  @IBOutlet var separatorWidthConstraint: NSLayoutConstraint!
  @IBOutlet var textField: CKPhoneNumberTextField!

  @IBAction func toggleCountryCodePicker(_ sender: Any) {
    delegate?.phoneNumberEntryViewDidTapCountryCodeButton(self)
  }

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

    applyCornerRadius(6)
    layer.borderColor = UIColor.lightBlueTint.cgColor
    layer.borderWidth = 1.0
    textField.borderStyle = .none

    adjustCorners(squareBottom: false)

    countryCodeButton.backgroundColor = .extraLightGrayBackground
    buttonSeparator.backgroundColor = .graySeparator
    separatorWidthConstraint.constant = 1 / UIScreen.main.nativeScale

    countryCodeButton.titleLabel?.font = PhoneNumberEntryView.flagFont
    loadFlagImage()
  }

  /// - parameter squareBottom: if true, only top corners are rounded/masked
  func adjustCorners(squareBottom: Bool) {
    self.layer.maskedCorners = squareBottom ? .top : .all
  }

  func configure(withCountry country: CKCountry) {
    self.selectedRegion = country.regionCode
    self.textField.update(withCountry: country)
    loadFlagImage()
  }

  private func loadFlagImage() {
    let flag = emojiFactory.emojiFlag(for: selectedRegion)
    self.countryCodeButton.setTitle(flag, for: .normal)
  }

}
