//
//  AppCoordinator+ViewControllerDismissable.swift
//  DropBit
//
//  Created by Ben Winters on 2/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol ViewControllerDismissable: AnyObject {

  /// The delegate should dismiss the viewController
  func viewControllerDidSelectClose(_ viewController: UIViewController)

}

extension AppCoordinator: ViewControllerDismissable {

  func viewControllerDidSelectClose(_ viewController: UIViewController) {
    var completion: (() -> Void)?
    switch viewController {
    case is GetBitcoinCopiedAddressViewController:
      completion = {
        guard let url = CoinNinjaUrlFactory.buildUrl(for: .buyWithCreditCard) else { return }
        self.openURLExternally(url, completionHandler: nil)
      }
    default:
      break
    }

    DispatchQueue.main.async {
      viewController.dismiss(animated: true, completion: completion)
    }
  }
}
