//
//  SuccessFailViewController.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/1/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol SuccessFailViewControllerDelegate: ViewControllerDismissable, URLOpener {
  func viewControllerDidRetry(_ viewController: SuccessFailViewController)
  func viewController(_ viewController: SuccessFailViewController, success: Bool, completion: (() -> Void)?)
}

class SuccessFailViewController: BaseViewController, StoryboardInitializable {

  var viewModel: SuccessFailViewModel = SuccessFailViewModel(mode: .pending)
  var action: (() -> Void)?

  static func newInstance(viewModel: SuccessFailViewModel,
                          delegate: SuccessFailViewControllerDelegate) -> SuccessFailViewController {
    let vc = SuccessFailViewController.makeFromStoryboard()
    vc.viewModel = viewModel
    vc.generalCoordinationDelegate = delegate
    vc.modalPresentationStyle = .overFullScreen
    return vc
  }

  func setMode(_ mode: SuccessFailView.Mode) {
    self.viewModel.mode = mode
    reloadViewWithModel()
  }

  func setURL(_ url: URL?) {
    self.viewModel.url = url
    reloadViewWithModel()
  }

  var coordinationDelegate: SuccessFailViewControllerDelegate? {
    return generalCoordinationDelegate as? SuccessFailViewControllerDelegate
  }

  @IBOutlet var successFailView: SuccessFailView!
  @IBOutlet var closeButton: UIButton!

  @IBOutlet var titleLabel: UILabel! {
    didSet {
      titleLabel.font = .medium(20)
      titleLabel.textColor = .darkGrayText
    }
  }

  @IBOutlet var subtitleLabel: UILabel! {
    didSet {
      subtitleLabel.font = .regular(15)
      subtitleLabel.adjustsFontSizeToFitWidth = true
    }
  }

  @IBOutlet var urlButton: PrimaryActionButton!
  @IBOutlet var actionButton: PrimaryActionButton!

  @IBAction func urlButtonWasTouched(_ sender: Any) {
    guard let url = viewModel.url else { return }
    coordinationDelegate?.openURLExternally(url, completionHandler: nil)
  }

  @IBAction func actionButtonWasTouched() {
    switch viewModel.mode {
    case .success:
      coordinationDelegate?.viewController(self, success: true, completion: nil)
    case .failure:
      if let retryAction = action {
        coordinationDelegate?.viewControllerDidRetry(self)
        self.setMode(.pending)
        retryAction()
      }
    default:
      break
    }
  }

  @IBAction func closeButtonWasTouched() {
    coordinationDelegate?.viewControllerDidSelectClose(self)
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
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    reloadViewWithModel()
  }

  private func reloadViewWithModel() {
    guard viewIfLoaded != nil else { return }

    DispatchQueue.main.async {
      self.configureView(with: self.viewModel)
    }
  }

  private func configureView(with vm: SuccessFailViewModel) {
    closeButton.alpha = alpha(for: vm.shouldShowCloseButton)
    closeButton.isUserInteractionEnabled = vm.shouldShowCloseButton

    titleLabel.text = vm.title
    successFailView.mode = vm.mode

    subtitleLabel.text = vm.subtitle
    subtitleLabel.textColor = .darkGrayText
    subtitleLabel.isHidden = !vm.shouldShowSubtitle

    urlButton.style = .darkBlue
    urlButton.isHidden = !vm.shouldShowURLButton
    urlButton.setTitle(vm.urlButtonTitle, for: .normal)

    actionButton.style = vm.primaryButtonStyle
    actionButton.setTitle(vm.primaryButtonTitle, for: .normal)
    actionButton.alpha = alpha(for: vm.shouldShowPrimaryButton)
    actionButton.isUserInteractionEnabled = vm.shouldShowPrimaryButton
  }

  private func alpha(for shouldShow: Bool) -> CGFloat {
    return shouldShow ? 1.0 : 0.0
  }

}
