//
//  SpendBitcoinViewController.swift
//  DropBit
//
//  Created by BJ Miller on 4/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

final class SpendBitcoinViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var headerLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()

    headerLabel.textColor = Theme.Color.grayText.color
    headerLabel.font = Theme.Font.sendingBitcoinAmount.font
  }

}
