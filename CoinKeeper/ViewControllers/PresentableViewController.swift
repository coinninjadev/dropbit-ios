//
//  PresentableViewController.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/7/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class PresentableViewController: BaseViewController, UIViewControllerTransitioningDelegate {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.layer.cornerRadius = 20
    view.layer.masksToBounds = true
    view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  private func initialize() {
    transitioningDelegate = self
    modalPresentationStyle = .custom
  }

  func presentationController(forPresented presented: UIViewController,
                              presenting: UIViewController?,
                              source: UIViewController) -> UIPresentationController? {
    return PresentationController(presentedViewController: presented, presenting: presenting)
  }
}
