//
//  TutorialScreenViewController.swift
//  DropBit
//
//  Created by Mitchell on 7/16/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import Gifu

protocol TutorialScreenViewControllerDelegate: class {
  func viewControllerActionWasPressed(_ viewController: TutorialScreenViewController)
  func viewControllerUrlWasPressed(_ viewController: TutorialScreenViewController, url: URL)
}

class TutorialScreenViewController: BaseViewController, StoryboardInitializable {

  enum Mode {
    case halfPhone
    case fullPhone
  }

  @IBOutlet var halfPhoneView: UIView!
  @IBOutlet var fullPhoneView: UIView!
  @IBOutlet var halfPhoneGifImageView: UIImageView!
  @IBOutlet var fullPhoneImageView: UIImageView!
  @IBOutlet var containerView: UIView!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var disclaimerLabel: UILabel!
  @IBOutlet var actionButton: PrimaryActionButton!
  @IBOutlet var linkButton: UnderlinedTextButton!

  private(set) weak var delegate: TutorialScreenViewControllerDelegate!
  private(set) var viewModel: TutorialScreenViewModel!

  static func newInstance(viewModel: TutorialScreenViewModel,
                          delegate: TutorialScreenViewControllerDelegate) -> TutorialScreenViewController {
    let vc = TutorialScreenViewController.makeFromStoryboard()
    vc.viewModel = viewModel
    vc.delegate = delegate
    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()

    guard let viewModel = viewModel, let imageData = UIImage.data(asset: viewModel.imageName) else { return }

    switch viewModel.mode {
    case .halfPhone:
      halfPhoneGifImageView.prepareForAnimation(withGIFData: imageData)
    default:
      break
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    switch viewModel.mode {
    case .halfPhone:
      containerView.addSubview(halfPhoneView)
      setupContainerViewConstraints(for: halfPhoneView)
      halfPhoneGifImageView.startAnimatingGIF()
    case .fullPhone:
      containerView.addSubview(fullPhoneView)
      setupContainerViewConstraints(for: fullPhoneView)
      fullPhoneImageView.image = UIImage(named: viewModel.imageName)
    }
  }

  private func setupContainerViewConstraints(for view: UIView) {
    view.translatesAutoresizingMaskIntoConstraints = false
    view.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
    view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
    view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
  }

  private func setupUI() {
    view.backgroundColor = .darkBlueText
    titleLabel.adjustsFontSizeToFitWidth = true
    titleLabel.font = .medium(20)
    detailLabel.font = .regular(13)

    titleLabel.text = viewModel?.title
    detailLabel.attributedText = viewModel?.detail

    disclaimerLabel.font = .regular(10)
    disclaimerLabel.textColor = .lightBlueTint

    if let buttonTitle = viewModel?.buttonTitle {
      actionButton.enable()
      actionButton.setTitle(buttonTitle, for: .normal)
    } else {
      actionButton.disable()
    }

    if let title = viewModel?.link?.title {
      linkButton.enable()
      linkButton.setUnderlinedTitle(title, size: 13, color: .lightBlueTint)
    } else {
      linkButton.disable()
    }

    if let disclaimerText = viewModel?.disclaimerText {
      disclaimerLabel.enable()
      disclaimerLabel.text = disclaimerText
    } else {
      disclaimerLabel.disable()
    }
  }

  @IBAction private func actionButtonWasPressed() {
    delegate?.viewControllerActionWasPressed(self)
  }

  @IBAction private func linkButtonWasPressed() {
    guard let link = viewModel?.link else { return }
    delegate?.viewControllerUrlWasPressed(self, url: link.url)
  }
}
