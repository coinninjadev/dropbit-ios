//
//  CountryCodeSearchView.swift
//  DropBit
//
//  Created by Ben Winters on 2/13/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol CountryCodeSearchViewDelegate: AnyObject {
  func countryCodeSearchView(_ searchView: CountryCodeSearchView, didSelectCountry country: CKCountry)
  func countryCodeSearchViewShouldDismiss(_ searchView: CountryCodeSearchView)
}

class CountryCodeSearchView: UIView {

  weak var delegate: CountryCodeSearchViewDelegate?
  var dataSource: CountryCodePickerDataSourceType?
  let flagFont = PhoneNumberEntryView.flagFont

  @IBOutlet var searchContainer: UIView!
  @IBOutlet var searchTextField: UITextField!
  @IBOutlet var searchSeparator: UIView!
  @IBOutlet var tableView: UITableView!

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
  }

  func setup() {
    backgroundColor = .lightGrayBackground
    tableView.backgroundColor = .clear
    applyCornerRadius(6)
    layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    layer.borderColor = UIColor.darkGrayBorder.cgColor
    layer.borderWidth = 1.0

    tableView.registerNib(cellType: CountryCodePickerCell.self)
    tableView.separatorStyle = .none
    tableView.delegate = self
    tableView.dataSource = self
    tableView.reloadData()

    configureSearchField()
  }

  private func configureSearchField() {
    searchContainer.backgroundColor = .whiteBackground
    searchSeparator.backgroundColor = .graySeparator

    let textColor = UIColor.searchResultGrayText
    searchTextField.textAlignment = .left
    searchTextField.textColor = textColor
    searchTextField.font = .regular(10)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .left
    let placeholder = NSMutableAttributedString.regular("Search Country",
                                                        size: 10.0,
                                                        color: textColor,
                                                        paragraphStyle: paragraphStyle)
    searchTextField.attributedPlaceholder = placeholder

    searchTextField.autocapitalizationType = .words
    searchTextField.autocorrectionType = .no
    searchTextField.returnKeyType = .done
    searchTextField.backgroundColor = .clear
    searchTextField.delegate = self
  }

}

extension CountryCodeSearchView: UITableViewDataSource {

  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let dataSource = self.dataSource else { return 0 }
    return dataSource.activeResults.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let country = countryCodePickerResult(for: indexPath),
      let cell = tableView.dequeueReusableCell(withIdentifier: CountryCodePickerCell.reuseIdentifier,
                                               for: indexPath) as? CountryCodePickerCell
      else { return UITableViewCell() }

    cell.configure(withCountry: country, flagFont: flagFont)

    return cell
  }

  func countryCodePickerResult(for indexPath: IndexPath) -> CKCountry? {
    guard let dataSource = self.dataSource else { return nil }
    return dataSource.activeResults[safe: indexPath.row]
  }

}

extension CountryCodeSearchView: UITableViewDelegate {

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let country = countryCodePickerResult(for: indexPath) else { return }
    delegate?.countryCodeSearchView(self, didSelectCountry: country)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    self.searchTextField.resignFirstResponder()
  }
}

extension CountryCodeSearchView: UITextFieldDelegate {

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let newText = NSString(string: textField.text ?? "").replacingCharacters(in: range, with: string)
    self.dataSource?.updateResults(forSearch: newText)
    self.tableView.reloadData()
    return true
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.delegate?.countryCodeSearchViewShouldDismiss(self)
    return false
  }

}
