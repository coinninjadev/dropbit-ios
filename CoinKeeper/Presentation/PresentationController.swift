//
//  PresentationController.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class PresentationController: UIPresentationController {
  private let shortTopDistance: CGFloat = 66.0
  private let tallTopDistance: CGFloat = 102.0
  private let dimmingView: UIView = {
    let dimmingView = UIView()
    dimmingView.backgroundColor = UIColor(white: 0, alpha: 0.5)
    dimmingView.alpha = 0
    return dimmingView
  }()

  // MARK: UIPresentationController
  override func presentationTransitionWillBegin() {
    guard let containerView = containerView, let presentedView = presentedView else { return }

    dimmingView.frame = containerView.bounds
    containerView.addSubview(dimmingView)
    containerView.addSubview(presentedView)

    guard let transitionCoordinator = presentingViewController.transitionCoordinator else { return }

    transitionCoordinator.animateAlongsideTransition(in: presentingViewController.view, animation: { _ in
      self.presentingViewController.view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
      self.presentingViewController.view.layer.cornerRadius = 20.0
      self.presentingViewController.view.layer.masksToBounds = true
      self.presentingViewController.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
      if !transitionCoordinator.isInteractive {
        (self.presentingViewController as? BaseViewController)?.statusBarStyle = .lightContent
      }
    })

    transitionCoordinator.animate(alongsideTransition: { _ in
      self.dimmingView.alpha = 1.0
    })
  }

  override func presentationTransitionDidEnd(_ completed: Bool) {
    if completed {
      (presentingViewController as? BaseViewController)?.statusBarStyle = .lightContent
    } else {
      dimmingView.removeFromSuperview()
    }
  }

  override func dismissalTransitionWillBegin() {
    guard let transitionCoordinator = presentingViewController.transitionCoordinator else { return }
    transitionCoordinator.animate(alongsideTransition: { _ in
      self.dimmingView.alpha = 0
    })

    transitionCoordinator.animateAlongsideTransition(in: presentingViewController.view, animation: { _ in
      self.presentingViewController.view.transform = CGAffineTransform.identity
      self.presentingViewController.view.layer.cornerRadius = 0.0
      self.presentingViewController.view.layer.masksToBounds = true
      self.presentingViewController.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
      if !transitionCoordinator.isInteractive {
        (self.presentingViewController as? BaseViewController)?.statusBarStyle = .default
      }
    })
  }

  override func dismissalTransitionDidEnd(_ completed: Bool) {
    guard completed else { return }
    guard let transitionCoordinator = presentingViewController.transitionCoordinator else { return }
    guard !transitionCoordinator.isCancelled else { return }

    dimmingView.removeFromSuperview()
    (presentingViewController as? BaseViewController)?.statusBarStyle = .default
  }

  override var frameOfPresentedViewInContainerView: CGRect {
    guard let containerView = containerView else { return .zero }
    var frame = containerView.bounds
    let distanceFromTop: CGFloat = UIScreen.main.relativeSize == .short ? shortTopDistance : tallTopDistance
    frame.size.height -= distanceFromTop
    frame.origin.y += distanceFromTop
    return frame
  }

  // MARK: UIViewController

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    guard let containerView = containerView else { return }
    coordinator.animate(alongsideTransition: { _ in
      self.dimmingView.frame = containerView.bounds
    })
  }
}
