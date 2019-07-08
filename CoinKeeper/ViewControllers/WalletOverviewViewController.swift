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
  
  private var pageControl: UIPageControl = UIPageControl()

  enum ViewControllerIndex: Int {
    case newsViewController = 0
    case transactionHistoryViewController = 1
    case requestViewController = 2
  }

  var baseViewControllers: [BaseViewController] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    dataSource = self

    setupPageControl()
    setupConstraints()
  }

  private func setupPageControl() {
    pageControl.currentPage = 1
    pageControl.pageIndicatorTintColor = .pageIndicator
    pageControl.currentPageIndicatorTintColor = .black
    pageControl.numberOfPages = baseViewControllers.count
    view.addSubview(pageControl)
    view.bringSubviewToFront(pageControl)
  }

  private func setupConstraints() {
    let heightConstant: CGFloat = UIScreen.main.bounds.height * 0.06 + view.safeAreaInsets.bottom
    pageControl.translatesAutoresizingMaskIntoConstraints = false
    pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -heightConstant).isActive = true
    pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
  }
}

extension WalletOverviewViewController: UIPageViewControllerDataSource {

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let baseViewController = viewController as? BaseViewController,
      let index = baseViewControllers.firstIndex(of: baseViewController), index != ViewControllerIndex.newsViewController.rawValue else { return nil }
    
    pageControl.currentPage = index

    return baseViewControllers[safe: index + 1] ?? viewController
  }

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let baseViewController = viewController as? BaseViewController,
      let index = baseViewControllers.firstIndex(of: baseViewController),
      index != ViewControllerIndex.requestViewController.rawValue else { return nil }
    
    pageControl.currentPage = index

    return baseViewControllers[safe: index - 1] ?? viewController
  }
}
