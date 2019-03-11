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
  var actions: [AlertActionConfigurationType] = []

  @IBOutlet var containerView: UIView!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var imageView: UIImageView!
  @IBOutlet var actionButton: PrimaryActionButton!

  func setup(with title: String?, description: String?, image: UIImage?, action: AlertActionConfigurationType) {
    displayTitle = title
    displayDescription = description
    self.image = image
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

    detailLabel.textColor = Theme.Color.errorRed.color
    detailLabel.font = Theme.Font.alertDetails.font
    titleLabel.font = Theme.Font.alertDetails.font

    imageView.image = image
    detailLabel.text = displayDescription

    styleTitleLabel()

    if let action = actions[safe: 0] {
      actionButton.setTitle(action.title, for: .normal)
    } else {
      actionButton.setTitle("", for: .normal)
    }
  }

  private func styleTitleLabel() {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    paragraphStyle.lineSpacing = 2.5

    let attrString = NSMutableAttributedString(string: displayTitle ?? "")
    attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrString.length))

    titleLabel.attributedText = attrString
  }

  @IBAction func actionButtonWasPressed() {
    guard let action = actions[safe: 0] else { return }

    dismiss(animated: true) {
      action.action?()
    }
  }
}
