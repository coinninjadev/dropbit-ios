//
//  ActionableAlertViewController.swift
//  DropBit
//
//  Created by Mitch on 10/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class ActionableAlertViewController: AlertControllerType, StoryboardInitializable, AccessibleViewSettable {

  var displayTitle: String?
  var displayDescription: String?
  var image: UIImage?
  var messageStyle: AlertMessageStyle = .standard
  var actions: [AlertActionConfigurationType] = []

  @IBOutlet var containerView: UIView!
  @IBOutlet var titleContainer: UIView!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var imageView: UIImageView!
  @IBOutlet var actionButton: PrimaryActionButton!

  func setup(with title: String?, description: String?, image: UIImage?, style: AlertMessageStyle, action: AlertActionConfigurationType) {
    self.displayTitle = title
    self.displayDescription = description
    self.image = image
    self.messageStyle = style
    self.actions = [action]
  }

  func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .actionableAlert(.page)),
      (actionButton, .actionableAlert(.actionButton))
    ]
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setAccessibilityIdentifiers()
    view.isOpaque = false
    containerView.applyCornerRadius(10)

    imageView.image = image

    configureTitleLabel()
    configureDetailLabel()

    if let action = actions.first {
      actionButton.setTitle(action.title, for: .normal)
    } else {
      actionButton.setTitle("", for: .normal)
    }
  }

  private func configureTitleLabel() {
    let shouldHideTitle = displayTitle == nil
    titleContainer.isHidden = shouldHideTitle
    titleLabel.isHidden = shouldHideTitle

    titleLabel.font = .regular(14)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    paragraphStyle.lineSpacing = 2.5

    if let title = displayTitle {
      let attrString = NSMutableAttributedString(string: title)
      attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrString.length))
      titleLabel.attributedText = attrString
    } else {
      titleLabel.attributedText = nil
    }
  }

  private func configureDetailLabel() {
    switch messageStyle {
    case .standard:
      detailLabel.textColor = .darkBlueText
    case .warning:
      detailLabel.textColor = .red
    }
    detailLabel.font = .regular(14)
    detailLabel.text = displayDescription
  }

  @IBAction func actionButtonWasPressed() {
    guard let action = actions.first else { return }

    dismiss(animated: true) {
      action.action?()
    }
  }
}
