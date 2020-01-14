//
//  AlertManager.swift
//  DropBit
//
//  Created by BJ Miller on 3/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PMAlertController
import SVProgressHUD
import SwiftMessages
import Sheeeeeeeeet

class AlertManager: AlertManagerType {
  private let notificationManager: NotificationManagerType

  weak var urlOpener: URLOpener?

  let bannerManager = SwiftMessages()

  lazy var phoneNumberFormatter: CKPhoneNumberFormatter = {
    return CKPhoneNumberFormatter(format: .national)
  }()

  required init(notificationManager: NotificationManagerType) {
    self.notificationManager = notificationManager
    setupAlertActionStyling()
    SVProgressHUD.setDefaultStyle(.dark)
  }

  func alert(from viewModel: AlertControllerViewModel) -> AlertControllerType {
    if viewModel.shouldCreateDefaultAlert {
      return defaultAlert(withTitle: viewModel.title, description: viewModel.description)
    } else {
      return alert(withTitle: viewModel.title, description: viewModel.description,
                   image: viewModel.image, style: viewModel.style, actionConfigs: viewModel.actions)
    }
  }

  private func setupAlertActionStyling() {
    let buttonStyle = ActionSheetButtonCell.appearance()
    buttonStyle.titleFont = .medium(16)
    buttonStyle.titleColor = .white
    buttonStyle.backgroundColor = .lightBlueTint

    let itemStyle = ActionSheetItemCell.appearance()
    itemStyle.titleFont = .medium(14)
  }

  func showActionSheet(in viewController: UIViewController,
                       with items: [ActionSheetItem],
                       actions: @escaping ActionSheet.SelectAction) {
    let button = ActionSheetOkButton(title: "CANCEL")
    let sheet = ActionSheet(items: items.appending(element: button), action: actions)
    sheet.presenter.isDismissableWithTapOnBackground = false
    sheet.present(in: viewController, from: nil)
  }

  func alert(withTitle title: String?,
             description: String?,
             image: UIImage?,
             style: AlertManager.AlertStyle,
             buttonLayout: AlertManagerButtonLayout,
             actionConfigs: [AlertActionConfigurationType]) -> AlertControllerType {
    return createAlert(withTitle: title,
                       description: description,
                       image: image, style: style,
                       buttonLayout: buttonLayout,
                       actionConfigs: actionConfigs)
  }

  func alert(withTitle title: String?,
             description: String?,
             image: UIImage?,
             style: AlertManager.AlertStyle,
             actionConfigs: [AlertActionConfigurationType]) -> AlertControllerType {

    return createAlert(withTitle: title, description: description, image: image, style: style, actionConfigs: actionConfigs)
  }

  func detailedAlert(withTitle title: String?,
                     description: String?,
                     image: UIImage,
                     style: AlertMessageStyle,
                     action: AlertActionConfigurationType) -> AlertControllerType {
    let alert = ActionableAlertViewController.newInstance(title: title, description: description,
                                                          image: image, style: style, action: action)
    alert.modalTransitionStyle = .crossDissolve
    alert.modalPresentationStyle = .overCurrentContext
    return alert
  }

  func showBanner(with message: String, duration: AlertDuration?) {
    showBanner(with: message, duration: duration, alertKind: .info, tapAction: nil, completion: nil)
  }

  func showBanner(with message: String, duration: AlertDuration?, alertKind kind: CKBannerViewKind) {
    showBanner(with: message, duration: duration, alertKind: kind, tapAction: nil, completion: nil)
  }

  func showBanner(with message: String, duration: AlertDuration?, alertKind kind: CKBannerViewKind, tapAction: CKCompletion? = nil) {
    showBanner(with: message, duration: duration, alertKind: kind, tapAction: tapAction, completion: nil, url: nil)
  }

  private func showBanner(with message: String,
                          duration: AlertDuration?,
                          alertKind kind: CKBannerViewKind = .info,
                          tapAction: CKCompletion? = nil,
                          completion: CKCompletion?, url: URL? = nil) {
    DispatchQueue.main.async { [weak self] in
      guard let strongSelf = self else { return }
      let bannerView: CKBannerView = .fromNib()
      bannerView.id = UUID().uuidString

      let padding: CGFloat = 8
      let width: CGFloat = (UIApplication.shared.keyWindow?.frame.width ?? 0) - (padding * 2)
      bannerView.frame = CGRect(x: padding, y: padding, width: width, height: 84)
      let foregroundColor = UIColor.whiteText

      let closeImage = UIImage(named: "close")?.withRenderingMode(.alwaysTemplate).maskWithColor(color: foregroundColor)
      bannerView.configure(message: message, image: closeImage, alertKind: kind, delegate: strongSelf)
      bannerView.url = url
      bannerView.completion = completion

      if let action = tapAction {
        bannerView.tapHandler = { [weak bannerView] _ in
          guard let banner = bannerView else { return }
          self?.didTapBanner(banner)
          action()
        }
      }

      let config = strongSelf.createConfig(with: duration)
      strongSelf.bannerManager.show(config: config, view: bannerView)
    }
  }

  private func createConfig(with duration: AlertDuration?) -> SwiftMessages.Config {
    var config = SwiftMessages.Config()
    if let seconds = duration?.value {
      config.duration = .seconds(seconds: seconds)
    } else {
      config.duration = .forever
    }

    config.presentationStyle = .top

    return config
  }

  func showIncomingTransactionAlert(for receivedAmount: Int, with rates: ExchangeRates) {
    let converter = CurrencyConverter(fromBtcTo: .USD,
                                      fromAmount: NSDecimalNumber(integerAmount: receivedAmount, currency: .BTC),
                                      rates: rates)
    let dollarAmount: String = FiatFormatter(currency: .USD, withSymbol: true).string(fromDecimal: converter.fiatAmount) ?? ""
    let message = "You have received a new transaction of \(dollarAmount) in bitcoin!"
    showIncomingAlertForCurrentAppState(with: message)
  }

  func showIncomingLightningAlert(for receivedAmount: Int, with rates: ExchangeRates) {
    let satsFormatter = SatsFormatter()
    var details = "!"
    if let amountString = satsFormatter.stringWithSymbol(fromSats: receivedAmount) {
      details = " of \(amountString)!"
    }
    let message = "You have received a new Lightning payment\(details)"
    showIncomingAlertForCurrentAppState(with: message, alertKind: .lightning)
  }

  private func showIncomingAlertForCurrentAppState(with message: String, alertKind: CKBannerViewKind = .info) {
    DispatchQueue.main.async {
      switch UIApplication.shared.applicationState {
      case .active:
        self.showBanner(with: message, duration: .default, alertKind: alertKind)
      case .background, .inactive:
        self.notificationManager.showNotification(with: NotificationDescription(title: "", body: message))
      @unknown default: break
      }
    }
  }

  func showAlert(for update: AddressRequestUpdateDisplayable) {
    switch update.side {
    case .sender:
      self.showSenderAlert(for: update)
    case .receiver:
      self.showReceiverAlert(for: update)
    }
  }

  private func showSenderAlert(for update: AddressRequestUpdateDisplayable) {
    let receiverDesc = update.receiverDescription(phoneFormatter: self.phoneNumberFormatter)
    switch update.status {
    case .completed:
      let stateDescriptor = (update.addressType == .btc) ? "sent" : "received" //lightning invites are instantly transferred
      let message = "Your transaction of \(update.fiatDescription) to \(receiverDesc) has been \(stateDescriptor)!"

      DispatchQueue.main.async {
        switch UIApplication.shared.applicationState {
        case .active:
          self.showBanner(with: message)
        case .background, .inactive:
          self.notificationManager.showNotification(with: NotificationDescription(title: "DropBit completed", body: message))
        @unknown default: break
        }
      }
    case .canceled:
      // Likely triggered because the DropBit was sent and then another app spent the vouts before we could execute the transaction.
      let message = "Your DropBit of \(update.fiatDescription) to \(receiverDesc) has been canceled due to insufficient funds."
      self.showBanner(with: message, duration: .default, alertKind: .error)
    case .expired:
      let message = """
        For security purposes we can only allow 48 hours for a \(CKStrings.dropBitWithTrademark) to be completed.
        Your DropBit sent to \(receiverDesc) has expired. Please try sending again.
        """.removingMultilineLineBreaks()
      self.showBanner(with: message, duration: .default, alertKind: .error)

    default:
      break
    }
  }

  private func showReceiverAlert(for update: AddressRequestUpdateDisplayable) {
    let senderDesc = update.senderDescription(phoneFormatter: self.phoneNumberFormatter)
    switch update.status {
    case .addressProvided:
      guard update.addressType == .btc else { return }
      let message = "We have sent a Bitcoin address to \(senderDesc) for \(update.fiatDescription) to be sent."
      self.showBanner(with: message, duration: .custom(8.0), alertKind: .info)
    case .completed:
      guard update.addressType == .btc else { return }
      let message = "The \(CKStrings.dropBitWithTrademark) for \(update.fiatDescription) from \(senderDesc) has been completed."
      self.showBanner(with: message, duration: .default, alertKind: .info)
    case .canceled:
      let message = "\(senderDesc) has canceled the DropBit for \(update.fiatDescription)"
      self.showBanner(with: message, duration: .default, alertKind: .error)
    case .expired:
      let message = """
        For security purposes we can only allow 48 hours for a \(CKStrings.dropBitWithTrademark) to be completed.
        Your DropBit from \(senderDesc) has expired.
        """.removingMultilineLineBreaks()
      self.showBanner(with: message, duration: .default, alertKind: .error)
    default:
      break
    }
  }

  private func sendDebugInfoAlertActionConfig(with action: @escaping CKCompletion) -> AlertActionConfiguration {
    return AlertActionConfiguration(title: "Send Debug Info", style: .default, action: {
      action()
    })
  }

  func debugAlert(with error: Error, debugAction action: @escaping CKCompletion) -> AlertControllerType {
    let message = """
      An error occurred: \(error.localizedDescription).
      If this problem continues, please contact support with your debug information
    """
    return createAlert(withTitle: "Error", description: message,
                       image: nil,
                       style: .alert,
                       actionConfigs: [okAlertActionConfig, sendDebugInfoAlertActionConfig(with: action)])
  }

  func showBannerAlert(for response: MessageResponse, completion: CKCompletion? = nil) {
    var title: String = response.body, kind: CKBannerViewKind

    switch response.level {
    case .warn:     kind = .warn
    case .info:     kind = .info
    case .success:  kind = .success
    case .error:    kind = .error
    default:        kind = .info
    }

    showBanner(with: title, duration: nil, alertKind: kind, completion: completion, url: response.link)
  }

  private func createAlert(withTitle title: String?,
                           description: String?,
                           image: UIImage?,
                           style: AlertManager.AlertStyle,
                           buttonLayout: AlertManagerButtonLayout = .horizontal,
                           actionConfigs: [AlertActionConfigurationType]) -> AlertControllerType {
    let pmStyle: PMAlertControllerStyle
    switch style {
    case .alert: pmStyle = .alert
    case .walkthrough: pmStyle = .alert
    }
    let alert = PMAlertController(title: title, description: description ?? "", image: image, style: pmStyle)
    alert.alertTitle.font = .medium(13)
    alert.alertTitle.textColor = .darkBlueText
    alert.alertDescription.isHidden = (description == nil)
    alert.gravityDismissAnimation = false
    actionConfigs.forEach { actionConfig in
      let action = PMAlertAction(title: actionConfig.title, style: self.pmAlertStyle(from: actionConfig.style), action: actionConfig.action)
      action.titleLabel?.font = .semiBold(13)
      action.setTitleColor(actionConfig.style.textColor, for: .normal)
      alert.addAction(action)
    }

    switch buttonLayout {
    case .vertical:
      alert.alertActionStackViewHeightConstraint.constant = alert.ALERT_STACK_VIEW_HEIGHT * CGFloat(alert.alertActionStackView.arrangedSubviews.count)
      alert.alertActionStackView.axis = .vertical
    default:
      break
    }

    return alert
  }

  enum AlertStyle {
    case alert, walkthrough
  }

  func okAlertActionConfig(action: CKCompletion?) -> AlertActionConfigurationType {
    return AlertActionConfiguration(title: "OK", style: .cancel, action: action)
  }

  func defaultAlert(withTitle title: String?, description: String?) -> AlertControllerType {
    return alert(withTitle: title,
                 description: description,
                 image: nil,
                 style: .alert,
                 actionConfigs: [okAlertActionConfig])
  }

  func alertActionSheet(withTitle title: String?,
                        message: String?,
                        options: [AlertActionConfiguration]) -> UIAlertController {
    let alertController: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

    for option in options {
      let action = UIAlertAction(title: option.title, style: .default) { action in
        option.action?()
      }

      alertController.addAction(action)
    }

    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

    alertController.addAction(cancelAction)

    return alertController
  }

  func showSuccess(message: String, forDuration duration: TimeInterval?) {
    DispatchQueue.main.async {
      SVProgressHUD.showSuccess(withStatus: message)
      duration.flatMap { SVProgressHUD.dismiss(withDelay: $0) }
    }
  }

  func showError(message: String, forDuration duration: TimeInterval?) {
    DispatchQueue.main.async {
      SVProgressHUD.showError(withStatus: message)
      duration.flatMap { SVProgressHUD.dismiss(withDelay: $0) }
    }
  }

  func showError(_ error: DisplayableError, forDuration duration: TimeInterval?) {
    showError(message: error.displayMessage, forDuration: duration)
  }

  private func pmAlertStyle(from style: AlertActionStyle) -> PMAlertActionStyle {
    switch style {
    case .cancel: return .cancel
    case .default: return .default
    }
  }

  func showActivityHUD(withStatus status: String?) {
    DispatchQueue.main.async {
      SVProgressHUD.show(withStatus: status)
    }
  }

  /// The delay can be used to ensure a minimum length for showing the indicator
  func hideActivityHUD(withDelay delay: TimeInterval?, completion: CKCompletion?) {
    DispatchQueue.main.async {
      SVProgressHUD.dismiss(withDelay: delay ?? 0, completion: completion)
    }
  }

  func showSuccessHUD(withStatus status: String?, duration: TimeInterval, completion: CKCompletion?) {
    guard let successImage = UIImage(named: "hudCheckmark") else { return }
    DispatchQueue.main.async {
      SVProgressHUD.setImageViewSize(CGSize(width: 35, height: 26))
      SVProgressHUD.setMinimumSize(CGSize(width: 172, height: 120))
      SVProgressHUD.show(successImage, status: status)
      SVProgressHUD.dismiss(withDelay: duration) {
        SVProgressHUD.setMinimumSize(SVProgressHUD.defaultMinimumSize)
        SVProgressHUD.setImageViewSize(SVProgressHUD.defaultImageViewSize)
        completion?()
      }
    }
  }

}

extension AlertManager {

  func didTapBanner(_ bannerView: CKBannerView) {
    //It's important to call hide() on the same instance of SwiftMessages that created the banner.
    //SwiftMessages.hide() is a convenience for SwiftMessages.sharedInstance.hide(), which is not the instance we are using.
    self.bannerManager.hide()

    if let url = bannerView.url {
      urlOpener?.openURL(url, completionHandler: nil)
    }
  }

  func didTapClose(_ bannerView: CKBannerView) {
    self.bannerManager.hide()
  }
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

  var textColor: UIColor {
    switch self {
    case .cancel:   return .darkBlueText
    case .default:  return .primaryActionButton
    }
  }
}

enum AlertManagerButtonLayout {
  case horizontal, vertical
}
