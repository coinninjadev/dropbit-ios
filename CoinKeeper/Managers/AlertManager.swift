//
//  AlertManager.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import PMAlertController
import SVProgressHUD
import SwiftMessages
import PhoneNumberKit

protocol AlertManagerType: CKBannerViewDelegate {
  func alert(
    withTitle title: String,
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

  func alert(
    withTitle title: String,
    description: String?,
    image: UIImage?,
    style: AlertManager.AlertStyle,
    buttonLayout: AlertManagerButtonLayout,
    actionConfigs: [AlertActionConfigurationType]
    ) -> AlertControllerType

  var urlOpener: URLOpener? { get set }

  func showSuccess(message: String, forDuration duration: TimeInterval?)
  func showError(message: String, forDuration duration: TimeInterval?)
  func defaultAlert(withTitle title: String, description: String?) -> AlertControllerType

  // Workaround for default parameter
  func showBanner(with message: String)
  func showBanner(with message: String, duration: AlertDuration?)
  func showBanner(with message: String, duration: AlertDuration?, alertKind kind: CKBannerViewKind)
  func showBanner(with message: String, duration: AlertDuration?, alertKind kind: CKBannerViewKind, tapAction: (() -> Void)?)

  /// This may be used to show either a banner or a local notification, depending on launchType (background status)
  func showAlert(for update: AddressRequestUpdateDisplayable)

  // used for showing new transactions incoming message
  func showIncomingTransactionAlert(for receivedAmount: Int, with rates: ExchangeRates)

  func showActivityHUD(withStatus status: String?)
  func hideActivityHUD(withDelay delay: TimeInterval?, completion: (() -> Void)?)
  func showSuccessHUD(withStatus status: String?, duration: TimeInterval, completion: (() -> Void)?)

  func showBannerAlert(for response: MessageResponse, completion: (() -> Void)?)

  init(notificationManager: NotificationManagerType)
}

extension AlertManagerType {

  // Satisfies protocol requirement and redirects to function with duration if this function without duration is called
  func showBanner(with message: String) {
    showBanner(with: message, duration: .default, alertKind: .info, tapAction: nil) // default parameter
  }

}

class AlertManager: AlertManagerType {

  private let notificationManager: NotificationManagerType

  weak var urlOpener: URLOpener?

  let bannerManager = SwiftMessages()

  private let phoneNumberKit = PhoneNumberKit()
  lazy var phoneNumberFormatter: CKPhoneNumberFormatter = {
    return CKPhoneNumberFormatter(kit: phoneNumberKit, format: .national)
  }()

  required init(notificationManager: NotificationManagerType) {
    self.notificationManager = notificationManager
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

  func alert(withTitle title: String,
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

  func alert(withTitle title: String,
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
    let alert = ActionableAlertViewController.makeFromStoryboard()
    alert.setup(with: title, description: description, image: image, style: style, action: action)
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

  func showBanner(with message: String, duration: AlertDuration?, alertKind kind: CKBannerViewKind, tapAction: (() -> Void)? = nil) {
    showBanner(with: message, duration: duration, alertKind: kind, tapAction: tapAction, completion: nil, url: nil)
  }

  private func showBanner(with message: String,
                          duration: AlertDuration?,
                          alertKind kind: CKBannerViewKind = .info,
                          tapAction: (() -> Void)? = nil,
                          completion: (() -> Void)?, url: URL? = nil) {
    DispatchQueue.main.async { [weak self] in
      guard let strongSelf = self else { return }
      let bannerView: CKBannerView = .fromNib()
      bannerView.id = UUID().uuidString

      let padding: CGFloat = 8
      let width: CGFloat = (UIApplication.shared.keyWindow?.frame.width ?? 0) - (padding * 2)
      bannerView.frame = CGRect(x: padding, y: padding, width: width, height: 76)
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
    let converter = CurrencyConverter(rates: rates,
                                      fromAmount: NSDecimalNumber(integerAmount: receivedAmount, currency: .BTC),
                                      fromCurrency: .BTC,
                                      toCurrency: .USD)
    let dollarAmount: String =  converter.amountStringWithSymbol(forCurrency: .USD) ?? ""
    let message = "You have recieved a new transaction of \(dollarAmount) in bitcoin!"
    DispatchQueue.main.async {
      switch UIApplication.shared.applicationState {
      case .active:
        self.showBanner(with: message)
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
      let message = "Your transaction of \(update.fiatDescription) to \(receiverDesc) has been sent!"

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
    case .addressSent:
      let message = "We have sent a Bitcoin address to \(senderDesc) for \(update.fiatDescription) to be sent."
      self.showBanner(with: message, duration: .custom(8.0), alertKind: .info)
    case .completed:
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

  func showBannerAlert(for response: MessageResponse, completion: (() -> Void)? = nil) {
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

  private func createAlert(withTitle title: String,
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
      action.setTitleColor(.primaryActionButton, for: .normal)
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

  func defaultAlert(withTitle title: String, description: String?) -> AlertControllerType {
    let okConfig = AlertActionConfiguration(title: "OK", style: .cancel, action: nil)
    let configs = [okConfig]
    return alert(withTitle: title,
                 description: description,
                 image: nil,
                 style: .alert,
                 actionConfigs: configs)
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
  func hideActivityHUD(withDelay delay: TimeInterval?, completion: (() -> Void)?) {
    DispatchQueue.main.async {
      SVProgressHUD.dismiss(withDelay: delay ?? 0, completion: completion)
    }
  }

  func showSuccessHUD(withStatus status: String?, duration: TimeInterval, completion: (() -> Void)?) {
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

enum AlertManagerButtonLayout {
  case horizontal
  case vertical
}

