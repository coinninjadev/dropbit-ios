//
//  SuccessFailViewController.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/1/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol SuccessFailViewControllerDelegate: ViewControllerDismissable {
  func viewControllerDidRetry(_ viewController: SuccessFailViewController)
  func viewController(_ viewController: SuccessFailViewController, success: Bool)
}

class SuccessFailViewController: BaseViewController, StoryboardInitializable {

  enum Mode {
    case pending
    case success
    case failure
  }

  var retryCompletion: (() -> Void)?

  var mode: Mode = .pending {
    didSet {
      setupModeStyling()
    }
  }

  var viewModel: SuccessFailViewModel = SuccessFailViewModel()

  var coordinationDelegate: SuccessFailViewControllerDelegate? {
    return generalCoordinationDelegate as? SuccessFailViewControllerDelegate
  }

  @IBOutlet var successFailView: SuccessFailView!
  @IBOutlet var closeButton: UIButton!

  @IBOutlet var titleLabel: UILabel! {
    didSet {
      titleLabel.font = Theme.Font.passFailTitle.font
      titleLabel.textColor = Theme.Color.grayText.color
    }
  }

  @IBOutlet var subtitleLabel: UILabel! {
    didSet {
      subtitleLabel.font = Theme.Font.passFailSubtitle.font
      subtitleLabel.adjustsFontSizeToFitWidth = true
    }
  }
  @IBOutlet var actionButton: PrimaryActionButton!

  @IBAction func actionButtonWasTouched() {
    switch mode {
    case .success:
      coordinationDelegate?.viewController(self, success: true)
    case .failure:
      if let retryRequestCompletion = retryCompletion {
        coordinationDelegate?.viewControllerDidRetry(self)
        mode = .pending
        retryRequestCompletion()
      }
    default:
      break
    }
  }

  @IBAction func closeButtonWasTouched() {
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }

  private func setupModeStyling() {
    DispatchQueue.main.async {
      switch self.mode {
      case .pending:
        self.actionButton?.alpha = 0.0
        self.titleLabel?.alpha = 0.0
        self.successFailView?.mode = .pending
      case .success:
        self.closeButton?.alpha = 0.0
        self.actionButton?.alpha = 1.0
        self.titleLabel?.alpha = 1.0
        self.titleLabel?.text = self.viewModel.successTitle
        self.subtitleLabel?.text = self.viewModel.successSubtitle
        self.subtitleLabel?.textColor = Theme.Color.grayText.color
        self.actionButton?.mode = .standard
        self.actionButton?.setTitle(self.viewModel.successButtonTitle, for: .normal)
        self.successFailView?.mode = .success
      case .failure:
        self.actionButton?.alpha = 1.0
        self.titleLabel?.alpha = 1.0
        self.titleLabel?.text = self.viewModel.failTitle
        self.subtitleLabel?.text = self.viewModel.failSubtitle
        self.subtitleLabel?.textColor = Theme.Color.errorRed.color
        self.actionButton?.mode = .error
        self.actionButton?.setTitle(self.viewModel.failButtonTitle, for: .normal)
        self.successFailView?.mode = .failure
      }
    }
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .successFail(.page)),
      (titleLabel, .successFail(.titleLabel)),
      (actionButton, .successFail(.actionButton))
    ]
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    titleLabel?.alpha = 0.0
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setupModeStyling()

    switch viewModel.flow {
    case .payment:
      closeButton?.alpha = 1.0
    case .restoreWallet:
      closeButton?.alpha = 0.0
    }
  }

}
