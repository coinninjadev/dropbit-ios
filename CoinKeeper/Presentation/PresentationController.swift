//
//  PresentationController.swift
//  DropBit
//
//  Created by BJ Miller on 4/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class PresentationController: UIPresentationController {

  private var shortTopDistance: CGFloat {
    if #available(iOS 13, *) {
      return 72.0
    } else {
      return 32.0
    }
  }

  private var mediumTopDistance: CGFloat {
    if #available(iOS 13, *) {
      return 72.0
    } else {
      return 44.0
    }
  }

  private var tallTopDistance: CGFloat {
    if #available(iOS 13, *) {
      return 100.0
    } else {
      return 66.0
    }
  }

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
      self.presentingViewController.view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
      self.presentingViewController.view.applyCornerRadius(20)
      self.presentingViewController.view.layer.maskedCorners = .top
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
      self.presentingViewController.view.applyCornerRadius(0)
      self.presentingViewController.view.layer.maskedCorners = .top
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
    var distanceFromTop: CGFloat = 0
    switch UIScreen.main.relativeSize {
    case .short: distanceFromTop = shortTopDistance
    case .medium: distanceFromTop = mediumTopDistance
    case .tall: distanceFromTop = tallTopDistance
    }
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
