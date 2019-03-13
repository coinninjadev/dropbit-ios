//
//  PhoneNumberEntryViewDisplayable.swift
//  DropBit
//
//  Created by Ben Winters on 2/28/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import PhoneNumberKit
import UIKit

protocol PhoneNumberEntryViewDisplayable: PhoneNumberEntryViewDelegate, CountryCodeSearchViewDelegate {

  var phoneNumberKit: PhoneNumberKit { get }
  var phoneNumberEntryView: PhoneNumberEntryView! { get }
  var countryCodeSearchView: CountryCodeSearchView? { get set }
  var countryCodeDataSource: CountryCodePickerDataSource { get }

  /// Optional method for updating UI outside of the PhoneNumberEntryView
  func phoneNumberEntryView(_ view: PhoneNumberEntryView, didSelectCountry country: CKCountry)

}

extension PhoneNumberEntryViewDisplayable {
  func phoneNumberEntryView(_ view: PhoneNumberEntryView, didSelectCountry country: CKCountry) { }
}

extension PhoneNumberEntryViewDisplayable where Self: UIViewController, Self: CKPhoneNumberTextFieldDelegate {

  /// Call this in viewDidLoad
  func setupPhoneNumberEntryView(textFieldEnabled: Bool) {
    phoneNumberEntryView.delegate = self
    phoneNumberEntryView.textField.phoneNumberTextFieldDelegate = self
    phoneNumberEntryView.textField.isUserInteractionEnabled = textFieldEnabled
    phoneNumberEntryView.configure(withCountry: CKCountry(locale: .current, kit: self.phoneNumberKit))
  }

  // MARK: Default implementations for PhoneNumberEntryViewDelegate & CountryCodeSearchViewDelegate

  func phoneNumberEntryViewDidTapCountryCodeButton(_ entryView: PhoneNumberEntryView) {
    if self.countryCodeSearchView == nil {
      self.showCountryCodeSearchView()
    } else {
      self.hideCountryCodeSearchView()
    }
  }

  func countryCodeSearchView(_ searchView: CountryCodeSearchView, didSelectCountry country: CKCountry) {
    self.phoneNumberEntryView.configure(withCountry: country)
    self.phoneNumberEntryView(phoneNumberEntryView, didSelectCountry: country)
    self.hideCountryCodeSearchView()

    // Activate textfield and move cursor to end
    guard let textField = self.phoneNumberEntryView.textField, textField.isUserInteractionEnabled else { return }
    textField.becomeFirstResponder()
    let newPosition = textField.endOfDocument
    textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
  }

  func countryCodeSearchViewShouldDismiss(_ searchView: CountryCodeSearchView) {
    hideCountryCodeSearchView()
  }

  private func showCountryCodeSearchView() {
    let searchView = CountryCodeSearchView(frame: CGRect.zero)
    searchView.translatesAutoresizingMaskIntoConstraints = false

    searchView.dataSource = self.countryCodeDataSource
    searchView.delegate = self
    searchView.setup()

    self.countryCodeSearchView = searchView
    self.view.addSubview(searchView)
    NSLayoutConstraint.activate([
      searchView.leadingAnchor.constraint(equalTo: self.phoneNumberEntryView.leadingAnchor),
      searchView.trailingAnchor.constraint(equalTo: self.phoneNumberEntryView.trailingAnchor),
      searchView.topAnchor.constraint(equalTo: self.phoneNumberEntryView.bottomAnchor),
      searchView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
      ]
    )

    self.phoneNumberEntryView.adjustCorners(squareBottom: true)
    searchView.searchTextField.becomeFirstResponder()
  }

  private func hideCountryCodeSearchView() {
    self.phoneNumberEntryView.adjustCorners(squareBottom: false)
    self.countryCodeSearchView?.removeFromSuperview()
    self.countryCodeSearchView = nil
    self.countryCodeDataSource.resetFilteredResults()
  }

}
