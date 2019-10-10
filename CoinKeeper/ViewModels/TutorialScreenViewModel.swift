//
//  TutorialScreenViewModel.swift
//  DropBit
//
//  Created by Mitchell on 7/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

typealias Link = (title: String, url: URL)

struct TutorialScreenViewModel {

  var imageName: String
  var title: String
  var detail: NSAttributedString
  var buttonTitle: String?
  var disclaimerText: String?
  var link: Link?
  var mode: TutorialScreenViewController.Mode
}

extension TutorialScreenViewModel: Equatable {
  static func == (lhs: TutorialScreenViewModel, rhs: TutorialScreenViewModel) -> Bool {
    return lhs.title == rhs.title
  }
}
