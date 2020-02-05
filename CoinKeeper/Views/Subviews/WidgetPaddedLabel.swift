//
//  WidgetPaddedLabel.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 1/29/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class WidgetPaddedLabel: PaddedLabel {

  override var padding: UIEdgeInsets {
    return UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 2)
  }
}
