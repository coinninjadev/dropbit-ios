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

  init(balances: WalletBalances) throws {
    //Validate the on chain and lightning balances, throw LightningWalletAmountValidatorError as appropriate
    self.balances = balances
  }

}

class LightningQuickLoadViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var backgroundView: UIView!
  @IBOutlet var contentView: UIView!
  @IBOutlet var balanceContainer: UIView!
  @IBOutlet var messageLabel: UILabel!
  @IBOutlet var customAmountButton: UIButton!

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

    customAmountButton.setTitle("CUSTOM", for: .normal)
    customAmountButton.titleLabel?.font = .semiBold(20)
    customAmountButton.setTitleColor(.mediumGrayBackground, for: .normal)
  }

}
