//
//  StoryboardInitializable.swift
//  DropBit
//
//  Created by BJ Miller on 2/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol StoryboardInitializable: AnyObject {
  static func makeFromStoryboard() -> Self
}

extension StoryboardInitializable {
  static func makeFromStoryboard() -> Self {
    let name = String(describing: self)
    //swiftlint:disable force_cast
    let viewController = UIStoryboard(name: name, bundle: nil)
      .instantiateViewController(withIdentifier: name) as! Self
    return viewController
  }
}
