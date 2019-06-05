//
//  CNContactSearchBar.swift
//  DropBit
//
//  Created by BJ Miller on 5/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class CNContactSearchBar: UISearchBar {

  var searchTextField: UITextField? {
    return value(forKey: "_searchField") as? UITextField
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    guard let textField = searchTextField else {
      return
    }

    textField.borderStyle = .none
    textField.font = .medium(12)
    textField.backgroundColor = .lightGrayBackground
    let leadingOffset = UIOffset(horizontal: CGFloat(30), vertical: CGFloat(0))
    setPositionAdjustment(leadingOffset, for: .search)
    textField.backgroundColor = .extraLightGrayBackground
    searchTextPositionAdjustment = UIOffset(horizontal: 10.0, vertical: 0.0)
    backgroundColor = .extraLightGrayBackground
  }
}
