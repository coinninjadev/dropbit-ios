//
//  CKBannerView.swift
//  DropBit
//
//  Created by Ben Winters on 7/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import SwiftMessages

enum CKBannerViewKind {
  case error, warn, success, info, lightning

  var backgroundColor: UIColor {
    switch self {
    case .error: return .darkPeach
    case .warn: return .bannerWarn
    case .success: return .bannerSuccess
    case .info: return .darkBlueBackground
    case .lightning: return .darkPurple
    }
  }

  var textColor: UIColor {
    switch self {
    case .info, .error, .warn, .success, .lightning: return .whiteText
    }
  }
}

protocol CKBannerViewDelegate: AnyObject {
  func didTapBanner(_ bannerView: CKBannerView)
  func didTapClose(_ bannerView: CKBannerView)
}

class CKBannerView: MessageView, AccessibleViewSettable {
  func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (closeButton, .bannerMessage(.close)),
      (messageLabel, .bannerMessage(.titleLabel)),
      (self, .bannerMessage(.page))
    ]
  }

  @IBOutlet weak var backingView: UIView!
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var closeButton: UIButton!

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  weak var delegate: CKBannerViewDelegate?
  var completion: CKCompletion?
  var url: URL?

  /// Configure a CKBannerView object for display
  ///
  /// - Parameters:
  ///   - message: The message to show to the user in the banner
  ///   - image: An image to show on the right side of the banner
  ///   - kind: Type of banner to display; info or error. The kind contains the color.
  func configure(message: String, image: UIImage?, alertKind kind: CKBannerViewKind, delegate: CKBannerViewDelegate, url: URL? = nil) {
    self.delegate = delegate

    tapHandler = { [weak self] _ in
      guard let localSelf = self else { return }
      localSelf.delegate?.didTapBanner(localSelf)
    }

    // Use custom background view
    backgroundColor = .clear
    backingView.applyCornerRadius(6)
    backingView.backgroundColor = kind.backgroundColor

    messageLabel.text = message
    closeButton.imageView?.contentMode = .scaleAspectFit
    closeButton.setImage(image, for: .normal)
    closeButton.setAccessibilityId(.bannerMessage(.close))

    messageLabel.font = .regular(13)
    messageLabel.textColor = kind.textColor
    self.url = url
  }

  deinit {
    completion?()
  }

  @IBAction func closeButtonWasTouched() {
    delegate?.didTapClose(self)
  }
}
