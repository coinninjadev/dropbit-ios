//
//  LightningQuickLoadViewController.swift
//  DropBit
//
//  Created by Ben Winters on 11/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol LightningQuickLoadViewControllerDelegate: ViewControllerDismissable {

  func viewControllerDidConfirmQuickLoad(_ viewController: LightningQuickLoadViewController,
                                         amount: Money,
                                         isMax: Bool)

  func viewControllerDidRequestCustomAmountLoad(_ viewController: LightningQuickLoadViewController)
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

  @IBAction func performCustomAmount(_ sender: Any) {
    delegate.viewControllerDidRequestCustomAmountLoad(self)
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

    addControls(from: viewModel.controlConfigs, startIndex: 0, to: topStackView)
    addControls(from: viewModel.controlConfigs, startIndex: 3, to: bottomStackView)
  }

  private func addControls(from configs: [QuickLoadControlConfig], startIndex: Int, to stackView: UIStackView) {
    let controlSize = CGSize(width: stackView.frame.height, height: stackView.frame.height)

    let endIndex = startIndex + 3
    for i in startIndex..<endIndex {
      let config = configs[i]

      let control = QuickLoadControl(frame: CGRect(origin: .zero, size: controlSize))
      control.configure(with: config, index: i, delegate: self)
      control.translatesAutoresizingMaskIntoConstraints = false
      control.constrain(toSize: controlSize)
      stackView.addArrangedSubview(control)
    }
  }

}

extension LightningQuickLoadViewController: LongPressConfirmButtonDelegate {

  func confirmationButtonDidConfirm(_ button: LongPressConfirmButton) {
    let config = viewModel.controlConfigs[button.tag]
    delegate.viewControllerDidConfirmQuickLoad(self, amount: config.amount, isMax: config.isMax)
  }

}
