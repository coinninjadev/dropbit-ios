//
//  RequestPayViewController.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol RequestPayViewControllerDelegate: ViewControllerDismissable {
  func viewControllerDidSelectSendRequest(_ viewController: UIViewController, payload: [Any])
  func viewControllerSuccessfullyCopiedToClipboard(_ viewController: UIViewController)
}

final class RequestPayViewController: PresentableViewController, StoryboardInitializable {

  // MARK: outlets
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var titleLabel: UILabel! {
    didSet {
      titleLabel.font = Theme.Font.onboardingSubtitle.font
      titleLabel.textColor = Theme.Color.darkBlueText.color
    }
  }
  @IBOutlet var primaryCurrencyLabel: UILabel! {
    didSet {
      primaryCurrencyLabel.textColor = Theme.Color.lightBlueTint.color
      primaryCurrencyLabel.font = Theme.Font.requestPayPrimaryCurrency.font
    }
  }
  @IBOutlet var secondaryCurrencyLabel: UILabel! {
    didSet {
      secondaryCurrencyLabel.textColor = Theme.Color.grayText.color
      secondaryCurrencyLabel.font = Theme.Font.requestPaySecondaryCurrency.font
    }
  }
  @IBOutlet var qrImageView: UIImageView!
  @IBOutlet var receiveAddressLabel: UILabel! {
    didSet {
      receiveAddressLabel.textColor = Theme.Color.darkBlueText.color
      receiveAddressLabel.font = Theme.Font.requestPayAddress.font
    }
  }
  @IBOutlet var receiveAddressTapGesture: UITapGestureRecognizer!
  @IBOutlet var receiveAddressBGView: UIView! {
    didSet {
      receiveAddressBGView.setCornerRadius(4)
      receiveAddressBGView.layer.borderColor = Theme.Color.lightGrayOutline.color.cgColor
      receiveAddressBGView.layer.borderWidth = 2.0
      receiveAddressBGView.backgroundColor = .clear
    }
  }
  @IBOutlet var tapInstructionLabel: UILabel! {
    didSet {
      tapInstructionLabel.textColor = Theme.Color.grayText.color
      tapInstructionLabel.font = Theme.Font.smallInfoLabel.font
    }
  }
  @IBOutlet var sendRequestButton: PrimaryActionButton! {
    didSet {
      sendRequestButton.setTitle("SEND REQUEST", for: .normal)
    }
  }

  // MARK: variables
  var coordinationDelegate: RequestPayViewControllerDelegate? {
    return generalCoordinationDelegate as? RequestPayViewControllerDelegate
  }
  var viewModel: RequestPayViewModelType?

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .requestPay(.page)),
      (receiveAddressLabel, .requestPay(.addressLabel))
    ]
  }

  // MARK: view lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    guard let viewModel = viewModel else { return }
    receiveAddressLabel.text = viewModel.bitcoinUrl.components.address
    qrImageView.image = viewModel.qrImage(withSize: qrImageView.frame.size)

    [primaryCurrencyLabel, secondaryCurrencyLabel].forEach { $0.isHidden = !viewModel.hasFundsInRequest }
    primaryCurrencyLabel.text = viewModel.primaryCurrencyValue
    secondaryCurrencyLabel.attributedText = viewModel.secondaryCurrencyValue
  }

  @IBAction func closeButtonTapped(_ sender: UIButton) {
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }

  @IBAction func sendRequestButtonTapped(_ sender: UIButton) {
    var payload: [Any] = []
    qrImageView.image.flatMap { $0.pngData() }.flatMap { payload.append($0) }
    if let viewModel = viewModel {
      if let amount = viewModel.bitcoinUrl.components.amount, amount > 0 {
        payload.append(viewModel.bitcoinUrl.absoluteString) //include amount details
      } else if let address = viewModel.bitcoinUrl.components.address {
        payload.append(address)
      }
    }
    coordinationDelegate?.viewControllerDidSelectSendRequest(self, payload: payload)
  }

  @IBAction func addressTapped(_ sender: UITapGestureRecognizer) {
    UIPasteboard.general.string = viewModel?.bitcoinUrl.components.address
    coordinationDelegate?.viewControllerSuccessfullyCopiedToClipboard(self)
  }
}
