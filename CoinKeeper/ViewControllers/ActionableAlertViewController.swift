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
    containerView.layer.cornerRadius = 10.0
    containerView.clipsToBounds = true

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

    titleLabel.font = Theme.Font.alertDetails.font

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
      detailLabel.textColor = Theme.Color.darkBlueText.color
    case .warning:
      detailLabel.textColor = Theme.Color.errorRed.color
    }
    detailLabel.font = Theme.Font.alertDetails.font
    detailLabel.text = displayDescription
  }

  @IBAction func actionButtonWasPressed() {
    guard let action = actions.first else { return }

    dismiss(animated: true) {
      action.action?()
    }
  }
}
