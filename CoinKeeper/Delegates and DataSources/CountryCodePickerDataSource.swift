//
//  CountryCodePickerDataSource.swift
//  DropBit
//
//  Created by Ben Winters on 2/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation

protocol CountryCodePickerDataSourceType: AnyObject {

  var searchText: String? { get set }
  var allCountries: [CKCountry] { get set }
  var filteredCountries: [CKCountry] { get set }

  func loadAllCountries()
  func updateResults(forSearch searchText: String)

}

extension CountryCodePickerDataSourceType {

  var activeResults: [CKCountry] {
    if searchText == nil {
      return allCountries
    } else {
      return filteredCountries
    }
  }

  func localizedCountryName(for regionCode: String) -> String? {
    let regionCode = regionCode.lowercased()
    return Locale.current.localizedString(forRegionCode: regionCode)
  }

  func loadAllCountries() {
    let allRegionCodes = phoneNumberKit.allCountries()
    let worldRegionCode = "001" // PhoneNumberKit includes some entries with the region as "World"
    let results: [CKCountry] = allRegionCodes.compactMap { regionCode in
      guard regionCode != worldRegionCode,
        let localizedName = localizedCountryName(for: regionCode),
        let countryCode = phoneNumberKit.countryCode(for: regionCode) else {
          return nil
      }
      return CKCountry(regionCode: regionCode, countryCode: Int(countryCode), localizedName: localizedName)
    }

    self.allCountries = results.sorted()
  }

  func updateResults(forSearch searchText: String) {
    if searchText.isEmpty {
      self.searchText = nil
      self.filteredCountries = allCountries

    } else {
      self.searchText = searchText
      self.filteredCountries = allCountries.filter { country in
        guard country.localizedName.count >= searchText.count else { return false }

        let localizedNameResult = country.localizedName.compare(searchText,
                                                                options: [.caseInsensitive, .diacriticInsensitive],
                                                                range: searchText.startIndex ..< searchText.endIndex)
        let localizedNameMatches = localizedNameResult == .orderedSame
        let regionCodeMatches = country.regionCode.lowercased() == searchText.lowercased()
        let acronymMatches = country.localizedAcronym() == searchText.uppercased()
        return localizedNameMatches || regionCodeMatches || acronymMatches
      }
    }
  }

}

class CountryCodePickerDataSource: CountryCodePickerDataSourceType {

  var searchText: String?
  var allCountries: [CKCountry] = []
  var filteredCountries: [CKCountry] = []

  init() {
    loadAllCountries()
  }

  /// Call this when dismissing the search view to reset the search results
  func resetFilteredResults() {
    self.updateResults(forSearch: "")
  }

}
