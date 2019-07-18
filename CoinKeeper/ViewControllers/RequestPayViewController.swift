//
//  RequestPayViewController.swift
//  CoinKeeper
//
//  Created by BJ Miller on 4/4/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol RequestPayViewControllerDelegate: ViewControllerDismissable, CopyToClipboardMessageDisplayable {
  func viewControllerDidSelectSendRequest(_ viewController: UIViewController, payload: [Any])
}

final class RequestPayViewController: PresentableViewController, StoryboardInitializable, CurrencySwappableAmountEditor {

  // MARK: outlets
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var titleLabel: UILabel! {
    didSet {
      titleLabel.font = .regular(15)
      titleLabel.textColor = .darkBlueText
    }
  }
  @IBOutlet var editAmountView: CurrencySwappableEditAmountView!
  @IBOutlet var qrImageView: UIImageView!
  @IBOutlet var receiveAddressLabel: UILabel! {
    didSet {
      receiveAddressLabel.textColor = .darkBlueText
      receiveAddressLabel.font = .semiBold(13)
    }
  }
  @IBOutlet var receiveAddressTapGesture: UITapGestureRecognizer!
  @IBOutlet var receiveAddressBGView: UIView! {
    didSet {
      receiveAddressBGView.applyCornerRadius(4)
      receiveAddressBGView.layer.borderColor = UIColor.mediumGrayBorder.cgColor
      receiveAddressBGView.layer.borderWidth = 2.0
      receiveAddressBGView.backgroundColor = .clear
    }
  }
  @IBOutlet var tapInstructionLabel: UILabel! {
    didSet {
      tapInstructionLabel.textColor = .darkGrayText
      tapInstructionLabel.font = .medium(10)
    }
  }
  @IBOutlet var sendRequestButton: PrimaryActionButton! {
    didSet {
      sendRequestButton.setTitle("SEND REQUEST", for: .normal)
    }
  }

  @IBOutlet var addAmountButton: UIButton! {
    didSet {
      addAmountButton.styleAddButtonWith(title: "Add Receive Amount")
    }
  }

  var isModal: Bool = true

  // MARK: variables
  var coordinationDelegate: RequestPayViewControllerDelegate? {
    return generalCoordinationDelegate as? RequestPayViewControllerDelegate
  }

  var viewModel: RequestPayViewModel!

  var editAmountViewModel: CurrencySwappableEditAmountViewModel {
    return viewModel
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .requestPay(.page)),
      (receiveAddressLabel, .requestPay(.addressLabel))
    ]
  }

  static func newInstance(delegate: RequestPayViewControllerDelegate,
                          receiveAddress: String,
                          currencyPair: CurrencyPair,
                          exchangeRates: ExchangeRates) -> RequestPayViewController {
    let vc = RequestPayViewController.makeFromStoryboard()
    vc.generalCoordinationDelegate = delegate
    let editAmountViewModel = CurrencySwappableEditAmountViewModel(exchangeRates: exchangeRates,
                                                                   primaryAmount: .zero,
                                                                   currencyPair: currencyPair,
                                                                   delegate: vc)
    vc.viewModel = RequestPayViewModel(receiveAddress: receiveAddress, viewModel: editAmountViewModel)
    return vc
  }

  // MARK: view lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    guard let viewModel = viewModel else { return }
    receiveAddressLabel.text = viewModel.bitcoinUrl.components.address
    qrImageView.image = viewModel.qrImage(withSize: qrImageView.frame.size)

    closeButton.isHidden = !isModal
  }

  @IBAction func closeButtonTapped(_ sender: UIButton) {
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }

  @IBAction func addRequestAmountButtonTapped(_ sender: UIButton) {
    editAmountView.isHidden = false
    addAmountButton.isHidden = true
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
    coordinationDelegate?.viewControllerSuccessfullyCopiedToClipboard(message: "Address copied to clipboard!", viewController: self)
  }
}
