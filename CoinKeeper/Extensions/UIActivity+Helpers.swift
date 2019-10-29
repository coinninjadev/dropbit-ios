//
//  UIActivity+Helpers.swift
//  DropBit
//
//  Created by Ben Winters on 10/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

extension UIActivity {

  static var standardExcludedTypes: [UIActivity.ActivityType] {
    return [
      .addToReadingList,
      .assignToContact,
      .markupAsPDF,
      .openInIBooks,
      .postToFacebook,
      .postToFlickr,
      .postToTencentWeibo,
      .postToTwitter,
      .postToVimeo,
      .postToWeibo,
      .saveToCameraRoll
    ]
  }

}
