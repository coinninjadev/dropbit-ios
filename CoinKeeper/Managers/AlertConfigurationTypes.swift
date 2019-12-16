//
//  AlertConfigurationTypes.swift
//  DropBit
//
//  Created by Ben Winters on 6/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

typealias AlertControllerType = UIViewController & AlertControllerProtocol

struct AlertControllerViewModel {
  var title: String?
  var description: String?
  var image: UIImage?
  var style: AlertManager.AlertStyle = .alert
  var actions: [AlertActionConfigurationType] = []

  init(title: String?, description: String? = nil,
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

struct AlertActionConfiguration: AlertActionConfigurationType {
  let title: String
  let style: AlertActionStyle
  let action: CKCompletion?
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
