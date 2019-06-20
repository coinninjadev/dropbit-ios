//
//  AlertConfigurationTypes.swift
//  DropBit
//
//  Created by Ben Winters on 6/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import PMAlertController
import UIKit

typealias AlertControllerType = UIViewController & AlertControllerProtocol

struct AlertControllerViewModel {
  var title: String
  var description: String?
  var image: UIImage?
  var style: AlertManager.AlertStyle = .alert
  var actions: [AlertActionConfigurationType] = []

  init(title: String, description: String? = nil,
       image: UIImage? = nil, style: AlertManager.AlertStyle = .alert,
       actions: [AlertActionConfigurationType] = []) {
    self.title = title
    self.description = description
    self.image = image
    self.style = style
    self.actions = actions
  }

  var shouldCreateDefaultAlert: Bool {
    return image == nil && style == .alert && actions.isEmpty
  }
}

protocol AlertControllerProtocol: AnyObject {
  var displayTitle: String? { get }
  var displayDescription: String? { get }
  var image: UIImage? { get }
  var actions: [AlertActionConfigurationType] { get }
}

extension PMAlertController: AlertControllerProtocol {
  var displayTitle: String? {
    return alertTitle.text
  }
  var displayDescription: String? {
    return alertDescription.text
  }
  var image: UIImage? {
    return self.alertImage.image
  }
  var actions: [AlertActionConfigurationType] {
    return self
      .alertActionStackView
      .arrangedSubviews
      .compactMap { $0 as? PMAlertAction }
      .compactMap { pmAlertAction -> AlertActionConfigurationType in
        return AlertActionConfiguration(
          title: pmAlertAction.title(for: .normal) ?? "",
          style: AlertActionStyle(from: pmAlertAction.actionStyle),
          action: nil  // nil because PMAlertAction's `action` property is `fileprivate`
        )
    }
  }
}

protocol AlertActionConfigurationType {
  var title: String { get }
  var style: AlertActionStyle { get }
  var action: (() -> Void)? { get }
}

enum AlertMessageStyle {
  case standard, warning
}

enum AlertActionStyle {
  case cancel, `default`

  init(from pmAlertActionStyle: PMAlertActionStyle) {
    switch pmAlertActionStyle {
    case .cancel: self = .cancel
    case .default: self = .default
    }
  }
}

struct AlertActionConfiguration: AlertActionConfigurationType {
  let title: String
  let style: AlertActionStyle
  let action: (() -> Void)?
}

enum AlertDuration {
  case `default`
  case custom(TimeInterval)

  var value: TimeInterval {
    switch self {
    case .default:              return 5.0
    case .custom(let duration): return duration
    }
  }
}

