//
//  SuccessFailViewController.swift
//  DropBit
//
//  Created by Mitchell on 5/1/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PromiseKit

protocol SuccessFailViewControllerDelegate: ViewControllerDismissable, URLOpener {
  func viewControllerDidRetry(_ viewController: SuccessFailViewController)
  func viewController(_ viewController: SuccessFailViewController, success: Bool, completion: CKCompletion?)
}

class SuccessFailViewController: BaseViewController, StoryboardInitializable {

  var viewModel: SuccessFailViewModel = SuccessFailViewModel(mode: .pending)
  var action: CKCompletion?
  private(set) var initialAction: Promise<Void>!

  static func newInstance(viewModel: SuccessFailViewModel,
                          delegate: SuccessFailViewControllerDelegate,
                          initialAction: Promise<Void> = Promise.value(())) -> SuccessFailViewController {
    let vc = SuccessFailViewController.makeFromStoryboard()
    vc.viewModel = viewModel
    vc.delegate = delegate
    vc.initialAction = initialAction
    vc.modalPresentationStyle = .overFullScreen
    return vc
  }

  func setMode(_ mode: SuccessFailView.Mode) {
    DispatchQueue.main.async {
      self.viewModel.mode = mode
      self.reloadViewWithModel()
    }

  }

  func setURL(_ url: URL?) {
    DispatchQueue.main.async {
      self.viewModel.url = url
      self.reloadViewWithModel()
    }
  }

  private(set) weak var delegate: SuccessFailViewControllerDelegate!

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
    delegate.openURLExternally(url, completionHandler: nil)
  }

  @IBAction func actionButtonWasTouched() {
    switch viewModel.mode {
    case .success:
      delegate.viewController(self, success: true, completion: nil)
    case .failure:
      if let retryAction = action {
        delegate.viewControllerDidRetry(self)
        self.setMode(.pending)
        retryAction()
      }
    default:
      break
    }
  }

  @IBAction func closeButtonWasTouched() {
    delegate.viewControllerDidSelectClose(self)
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
    reloadViewWithModel()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    initialAction
      .done { _ in self.reloadViewWithModel() }
      .cauterize()
  }

  private func reloadViewWithModel() {
    guard viewIfLoaded != nil else { return }
    self.configureView(with: self.viewModel)
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
