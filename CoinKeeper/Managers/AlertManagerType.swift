//
//  AlertManagerType.swift
//  DropBit
//
//  Created by Ben Winters on 10/8/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PMAlertController
import Sheeeeeeeeet

protocol AlertManagerType: CKBannerViewDelegate {

  func alert(
    withTitle title: String?,
    description: String?,
    image: UIImage?,
    style: AlertManager.AlertStyle,
    actionConfigs: [AlertActionConfigurationType]
    ) -> AlertControllerType

  func detailedAlert(withTitle title: String?,
                     description: String?,
                     image: UIImage,
                     style: AlertMessageStyle,
                     action: AlertActionConfigurationType
    ) -> AlertControllerType

  func alert(from viewModel: AlertControllerViewModel) -> AlertControllerType
  func debugAlert(with error: Error, debugAction action: @escaping CKCompletion) -> AlertControllerType

  func alert(
    withTitle title: String?,
    description: String?,
    image: UIImage?,
    style: AlertManager.AlertStyle,
    buttonLayout: AlertManagerButtonLayout,
    actionConfigs: [AlertActionConfigurationType]
    ) -> AlertControllerType

  func okAlertActionConfig(action: CKCompletion?) -> AlertActionConfigurationType

  var urlOpener: URLOpener? { get set }

  func showSuccess(message: String, forDuration duration: TimeInterval?)
  func showError(message: String, forDuration duration: TimeInterval?)
  func showError(_ error: DisplayableError, forDuration duration: TimeInterval?)
  func defaultAlert(withTitle title: String?, description: String?) -> AlertControllerType

  // Workaround for default parameter
  func showBanner(with message: String)
  func showBanner(with message: String, duration: AlertDuration?)
  func showBanner(with message: String, duration: AlertDuration?, alertKind kind: CKBannerViewKind)
  func showBanner(with message: String, duration: AlertDuration?, alertKind kind: CKBannerViewKind, tapAction: CKCompletion?)

  /// This may be used to show either a banner or a local notification, depending on launchType (background status)
  func showAlert(for update: AddressRequestUpdateDisplayable)

  // used for showing new transactions incoming message
  func showIncomingTransactionAlert(for receivedAmount: Int, with rates: ExchangeRates)
  func showIncomingLightningAlert(for receivedAmount: Int, with rates: ExchangeRates)

  func showActivityHUD(withStatus status: String?)
  func hideActivityHUD(withDelay delay: TimeInterval?, completion: CKCompletion?)
  func showSuccessHUD(withStatus status: String?, duration: TimeInterval, completion: CKCompletion?)

  func showBannerAlert(for response: MessageResponse, completion: CKCompletion?)
  func showActionSheet(in viewController: UIViewController,
                       with items: [ActionSheetItem],
                       actions: @escaping ActionSheet.SelectAction)

  init(notificationManager: NotificationManagerType)
}

extension AlertManagerType {

  // Satisfies protocol requirement and redirects to function with duration if this function without duration is called
  func showBanner(with message: String) {
    showBanner(with: message, duration: .default, alertKind: .info, tapAction: nil) // default parameter
  }

  var okAlertActionConfig: AlertActionConfigurationType {
    okAlertActionConfig(action: nil)
  }

}

protocol AlertActionConfigurationType {
  var title: String { get }
  var style: AlertActionStyle { get }
  var action: CKCompletion? { get }
}

protocol AlertControllerProtocol: AnyObject {
  var displayTitle: String? { get }
  var displayDescription: String? { get }
  var image: UIImage? { get }
  var actions: [AlertActionConfigurationType] { get }
}
