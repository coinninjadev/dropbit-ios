//
//  TutorialViewController.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol TutorialViewControllerDelegate: ViewControllerDismissable {
  func tutorialViewControllerDidFinish(_ viewController: UIViewController)
}

class TutorialViewController: BasePageViewController, StoryboardInitializable {

  var coordinationDelegate: TutorialViewControllerDelegate? {
    return generalCoordinationDelegate as? TutorialViewControllerDelegate
  }

  weak var urlOpener: URLOpener?
  private var pageControl = UIPageControl()
  private var closeButton: UIButton = UIButton()

  fileprivate(set) var viewModels: [TutorialScreenViewModel] = []

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .tutorial(.page))
    ]
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    dataSource = self
    delegate = self

    viewModels = [pageOne(), pageTwo(), pageThree(), pageFour()]
    setupPageControl()
    setupCloseButton()
    setRootPageViewController()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    setupConstraints()
  }

  private func pageOne() -> TutorialScreenViewModel {
    let link: Link = (title: "Learn more about Bitcoin",
                      url: CoinNinjaUrlFactory.buildUrl(for: .bitcoin) ?? URL(fileURLWithPath: ""))
    let text: NSAttributedString = NSAttributedString(string: """
    Bitcoin is a currency that’s completely owned and controlled by you.
    It can be sent anywhere in the world, very quickly, cheaply and without the need for a 3rd party transmitter, like a bank.
    """.removingMultilineLineBreaks())
    return TutorialScreenViewModel(imageName: "bitcoinGif", title: "What is Bitcoin?",
                                   detail: text, buttonTitle: nil,
                                   disclaimerText: nil, link: link,
                                   mode: .halfPhone)
  }

  private func pageTwo() -> TutorialScreenViewModel {
    let link: Link = (title: "Learn why Bitcoin is better",
                      url: CoinNinjaUrlFactory.buildUrl(for: .whyBitcoin) ?? URL(fileURLWithPath: ""))
    let text = NSAttributedString(string: """
    Banks charge you fees, your dollar is consistently being
    devalued and it’s extremely hard to exchange or
    send currency for global use.
    """.removingMultilineLineBreaks())

    return TutorialScreenViewModel(imageName: "systemGif", title: "Why the system is broken",
                                   detail: text, buttonTitle: nil,
                                   disclaimerText: nil, link: link,
                                   mode: .halfPhone)
  }

  private func pageThree() -> TutorialScreenViewModel {
    let link: Link = (title: "Learn more about Recovery Words",
                      url: CoinNinjaUrlFactory.buildUrl(for: .seedWords) ?? URL(fileURLWithPath: ""))
    let text = NSAttributedString(string: """
    Recovery words consist of 12 or 24 words that will allow
    you to restore your wallet if anything happens to
    your phone. Treat this like your bank
    account password…they’re very important.
    """.removingMultilineLineBreaks())
    return TutorialScreenViewModel(imageName: "seedWordsGif", title: "Recovery Words",
                                   detail: text, buttonTitle: nil,
                                   disclaimerText: nil, link: link,
                                   mode: .halfPhone)
  }

  private func pageFour() -> TutorialScreenViewModel {
    let link: Link = (title: "Learn more about \(CKStrings.dropBitWithTrademark)",
      url: CoinNinjaUrlFactory.buildUrl(for: .bitcoinSMS) ?? URL(fileURLWithPath: ""))
    let text = NSAttributedString(string: """
    By adding your phone number it will
    allow you to transact Bitcoin with
    people in your contact list.
    """.removingMultilineLineBreaks())
    let disclaimer = "*You must verify your number if you are accepting Bitcoin from an SMS invite"
    return TutorialScreenViewModel(imageName: "tutorialDropBit", title: "Send Bitcoin via SMS",
                                   detail: text, buttonTitle: "LET'S GO",
                                   disclaimerText: disclaimer, link: link,
                                   mode: .fullPhone)
  }

  private func setupPageControl() {
    pageControl.currentPage = 0
    pageControl.pageIndicatorTintColor = .pageIndicator
    pageControl.currentPageIndicatorTintColor = .black
    pageControl.numberOfPages = viewModels.count
    view.addSubview(pageControl)
  }

  private func setupCloseButton() {
    closeButton.setImage(#imageLiteral(resourceName: "close-white"), for: .normal)
    closeButton.imageView?.contentMode = .scaleAspectFit
    closeButton.addTarget(self, action: #selector(closeButtonWasTouched), for: .touchUpInside)
    view.addSubview(closeButton)
  }

  private func setupConstraints() {
    let heightConstant: CGFloat = UIScreen.main.bounds.height * 0.06 + view.safeAreaInsets.bottom
    pageControl.translatesAutoresizingMaskIntoConstraints = false
    pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -heightConstant).isActive = true
    pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

    closeButton.translatesAutoresizingMaskIntoConstraints = false
    closeButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    closeButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
    closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25).isActive = true
    closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 45).isActive = true
  }

  private func setRootPageViewController() {
    let newPageViewController = TutorialScreenViewController.makeFromStoryboard()
    newPageViewController.viewModel = viewModels[viewModels.startIndex]
    newPageViewController.delegate = self
    setViewControllers([newPageViewController], direction: .forward, animated: false, completion: nil)
  }

  func createViewController(at index: Int) -> TutorialScreenViewController? {
    guard let viewModel = viewModels[safe: index] else { return nil }
    let viewController = TutorialScreenViewController.makeFromStoryboard()
    viewController.delegate = self
    viewController.viewModel = viewModel
    return viewController
  }

  @objc func closeButtonWasTouched() {
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }

  fileprivate func togglePageControl(for index: Int) {
    if index == viewModels.count - 1 {
      pageControl.disable()
    } else {
      pageControl.enable()
    }
  }
}

extension TutorialViewController: UIPageViewControllerDelegate {

  func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
    guard let nextViewController = pendingViewControllers.first as? TutorialScreenViewController,
      let viewModel = nextViewController.viewModel,
      let index = viewModels.index(of: viewModel) else { return }

    pageControl.currentPage = index

    togglePageControl(for: index)
  }

  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool,
                          previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    guard let nextViewController = previousViewControllers.first as? TutorialScreenViewController,
      let viewModel = nextViewController.viewModel,
      let index = viewModels.index(of: viewModel) else { return }

    if !completed {
      pageControl.currentPage = index
      togglePageControl(for: index)
    }
  }
}

extension TutorialViewController: TutorialScreenViewControllerDelegate {

  func viewControllerActionWasPressed(_ viewController: TutorialScreenViewController) {
    coordinationDelegate?.tutorialViewControllerDidFinish(self)
  }

  func viewControllerUrlWasPressed(_ viewController: TutorialScreenViewController, url: URL) {
    urlOpener?.openURL(url, completionHandler: nil)
  }
}

extension TutorialViewController: UIPageViewControllerDataSource {

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let viewModel = (viewController as? TutorialScreenViewController)?.viewModel else { return nil }

    let index = viewModels.index(of: viewModel) ?? 0
    var newPageViewController: TutorialScreenViewController?

    if index > viewModels.startIndex {
      newPageViewController = TutorialScreenViewController.makeFromStoryboard()
      newPageViewController?.delegate = self
      newPageViewController?.viewModel = viewModels[index - 1]
    }

    return newPageViewController
  }

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let viewModel = (viewController as? TutorialScreenViewController)?.viewModel else { return nil }

    let index = viewModels.index(of: viewModel) ?? 0
    var newPageViewController: TutorialScreenViewController?

    if index < viewModels.endIndex - 1 {
      newPageViewController = TutorialScreenViewController.makeFromStoryboard()
      newPageViewController?.delegate = self
      newPageViewController?.viewModel = viewModels[index + 1]
    }

    return newPageViewController
  }
}
