//
//  SuccessFailViewModel.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/11/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

/// Provides default values appropriate for most success/fail scenarios.
/// Create a subclass if customization is needed.
class SuccessFailViewModel {
  var mode: SuccessFailView.Mode
  var url: URL?
  var shouldShowCloseButton: Bool = true

  required init(mode: SuccessFailView.Mode) {
    self.mode = mode
  }

  var title: String? {
    switch mode {
    case .pending:  return nil
    case .success:  return "SUCCESS"
    case .failure:  return "FAILED"
    }
  }

  var subtitle: String? {
    return nil
  }

  var subtitleTextColor: UIColor {
    switch mode {
    case .pending, .success:  return .grayText
    case .failure:            return .darkPeach
    }
  }

  var primaryButtonTitle: String? {
    switch mode {
    case .pending:    return nil
    case .success:    return "OK"
    case .failure:    return "TRY AGAIN"
    }
  }

  var primaryButtonStyle: PrimaryActionButton.Style {
    switch mode {
    case .pending, .success:  return .standard
    case .failure:            return .error
    }
  }

  /// Returns a string without the URL scheme
  var urlButtonTitle: String? {
    if url == nil {
      return nil
    } else {
      return "VIEW TWEET"
    }
  }

  var shouldShowTitle: Bool {
    return title != nil
  }

  var shouldShowSubtitle: Bool {
    return subtitle != nil
  }

  var shouldShowURLButton: Bool {
    return url != nil
  }

  var shouldShowPrimaryButton: Bool {
    return primaryButtonTitle != nil
  }

}

///Subclass for flow identification
class PaymentSuccessFailViewModel: SuccessFailViewModel { }

class RestoreWalletSuccessFailViewModel: SuccessFailViewModel {

  required init(mode: SuccessFailView.Mode) {
    super.init(mode: mode)
  }

  override var title: String? {
    switch mode {
    case .success:  return "WALLET RECOVERED"
    default:        return super.title
    }
  }

  override var subtitle: String? {
    switch mode {
    case .pending:  return super.subtitle
    case .success:  return "Your wallet is being imported"
    case .failure:  return "Failed to import your wallet. \nPlease try again"
    }
  }

  override var primaryButtonTitle: String? {
    switch mode {
    case .success:  return "GO TO MY WALLET"
    default:        return super.primaryButtonTitle
    }
  }

}
