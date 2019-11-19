//
//  LightningQuickLoadViewController.swift
//  DropBit
//
//  Created by Ben Winters on 11/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol LightningQuickLoadViewControllerDelegate: ViewControllerDismissable {

}

struct LightningQuickLoadViewModel {

  let balances: WalletBalances
  let currency: CurrencyCode
  let controlConfigs: [QuickLoadControlConfig]

  init(balances: WalletBalances, currency: CurrencyCode) throws {
    //Validate the on chain and lightning balances, throw LightningWalletAmountValidatorError as appropriate
    self.balances = balances
    self.currency = currency
    self.controlConfigs = LightningQuickLoadViewModel.configs(withMax: .one, currency: currency)
  }

  private static func configs(withMax max: NSDecimalNumber, currency: CurrencyCode) -> [QuickLoadControlConfig] {
    return []
  }

}

class LightningQuickLoadViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var backgroundView: UIView!
  @IBOutlet var contentView: UIView!
  @IBOutlet var balanceView: LoadLightningBalancesView!
  @IBOutlet var messageLabel: UILabel!
  @IBOutlet var customAmountButton: UIButton!
  @IBOutlet var topStackView: UIStackView!
  @IBOutlet var bottomStackView: UIStackView!

  @IBAction func performClose(_ sender: Any) {
    delegate.viewControllerDidSelectClose(self)
  }

  private var viewModel: LightningQuickLoadViewModel!
  private weak var delegate: LightningQuickLoadViewControllerDelegate!

  static func newInstance(viewModel: LightningQuickLoadViewModel,
                          delegate: LightningQuickLoadViewControllerDelegate) -> LightningQuickLoadViewController {
    let vc = LightningQuickLoadViewController.makeFromStoryboard()
    vc.viewModel = viewModel
    vc.delegate = delegate
    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupViews()
  }

  private func setupViews() {
    view.backgroundColor = .clear
    backgroundView.backgroundColor = .semiOpaquePopoverBackground
    contentView.applyCornerRadius(13)

    messageLabel.text = "TAP + HOLD FOR INSTANT \nLIGHTNING LOAD"
    messageLabel.font = .semiBold(14)
    messageLabel.textColor = .darkGrayText
    messageLabel.textAlignment = .center

    customAmountButton.setTitle("CUSTOM", for: .normal)
    customAmountButton.titleLabel?.font = .semiBold(20)
    customAmountButton.setTitleColor(.mediumGrayBackground, for: .normal)

    balanceView.configure(withFiatBalances: viewModel.balances, currency: viewModel.currency)

    for (i, config) in viewModel.controlConfigs.enumerated() {
      let control = QuickLoadControl(frame: .zero)
      control.configure(title: config.amount.displayString, delegate: self)
      //TODO: Set tag on LongPressConfirmButton to i
    }
  }

}

extension LightningQuickLoadViewController: LongPressConfirmButtonDelegate {
  func confirmationButtonDidConfirm(_ button: LongPressConfirmButton) {
    print("Button at index \(button.tag) did confirm")
  }
}
