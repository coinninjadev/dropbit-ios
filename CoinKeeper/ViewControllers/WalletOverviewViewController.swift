//
//  WalletOverviewViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/3/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class WalletOverviewViewController: BasePageViewController, StoryboardInitializable {
  
  enum ViewControllerIndex: Int {
    case newsViewController = 0
    case transactionHistoryViewController = 1
    case requestViewController = 2
  }
  
  var baseViewControllers: [BaseViewController] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    dataSource = self
  }
  
  override func setViewControllers(_ viewControllers: [UIViewController]?, direction: UIPageViewController.NavigationDirection, animated: Bool, completion: ((Bool) -> Void)? = nil) {
    super.setViewControllers(viewControllers, direction: direction, animated: animated, completion: completion)
    guard let viewControllers = viewControllers, viewControllers.isNotEmpty else { return }
    
    baseViewControllers = viewControllers.compactMap { $0 as? BaseViewController }
  }
}

extension WalletOverviewViewController: UIPageViewControllerDataSource {
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let baseViewController = viewController as? BaseViewController, let index = baseViewControllers.firstIndex(of: baseViewController), index != ViewControllerIndex.newsViewController.rawValue else { return nil }
    
    return baseViewControllers[safe: index + 1] ?? viewController
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let baseViewController = viewController as? BaseViewController, let index = baseViewControllers.firstIndex(of: baseViewController), index != ViewControllerIndex.requestViewController.rawValue else { return nil }
    
    return baseViewControllers[safe: index - 1] ?? viewController
  }
}
