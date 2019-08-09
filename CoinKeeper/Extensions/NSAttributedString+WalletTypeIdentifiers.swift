//
//  NSAttributedString+WalletTypeIdentifiers.swift
//  DropBit
//
//  Created by Mitchell Malleo on 8/9/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension NSAttributedString {

  static var lightningTitle: NSAttributedString {
    return NSAttributedString(imageName: "flashIcon", imageSize: CGSize(width: 11, height: 18),
                       title: "Lightning", sharedColor: .white, font: .medium(14))
  }

  static var bitcoinTitle: NSAttributedString {
    return NSAttributedString(imageName: "bitcoinIconFilled", imageSize: CGSize(width: 11, height: 18),
                       title: "Bitcoin", sharedColor: .white, font: .medium(14))
  }

  static var lightningUnselectedTitle: NSAttributedString {
    return NSAttributedString(imageName: "flashIcon", imageSize: CGSize(width: 11, height: 18),
                       title: "Lightning", sharedColor: .darkGrayBackground, font: .medium(14))
  }

  static var bitcoinUnselectedTitle: NSAttributedString {
    return NSAttributedString(imageName: "bitcoinIconFilled", imageSize: CGSize(width: 11, height: 18),
                       title: "Bitcoin", sharedColor: .darkGrayBackground, font: .medium(14))
  }

}
