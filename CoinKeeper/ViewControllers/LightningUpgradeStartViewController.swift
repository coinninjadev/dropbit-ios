//
//  LightningUpgradeStartViewController.swift
//  DropBit
//
//  Created by BJ Miller on 8/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import Cnlib

protocol LightningUpgradeStartViewControllerDelegate: AnyObject {
  func viewControllerRequestedShowLightningUpgradeInfo(_ viewController: LightningUpgradeStartViewController)
  func viewControllerRequestedUpgradeAuthentication(_ viewController: LightningUpgradeStartViewController, completion: @escaping CKCompletion)
}

final class LightningUpgradeStartViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var overlayView: LightningUpgradeGradientOverlayView!
  @IBOutlet var lightningTitleLabel: UILabel!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var upgradeButton: PrimaryActionButton!
  @IBOutlet var infoButton: UIButton!
  @IBOutlet var activityIndicator: UIActivityIndicatorView!
  @IBOutlet var activityIndicatorBottomConstraint: NSLayoutConstraint!
  @IBOutlet var confirmNewWordsSelectionView: UIView!
  @IBOutlet var confirmNewWordsLabel: UILabel!
  @IBOutlet var confirmNewWordsCheckboxBackgroundView: UIView!
  @IBOutlet var confirmNewWordsCheckmarkImage: UIImageView!
  @IBOutlet var confirmTransferFundsView: UIView!
  @IBOutlet var confirmTransferFundsLabel: UILabel!
  @IBOutlet var confirmTransferFundsCheckboxBackgroundView: UIView!
  @IBOutlet var confirmTransferFundsCheckmarkImage: UIImageView!

  static func newInstance(
    delegate: LightningUpgradeStartViewControllerDelegate,
    nextStep: @escaping CKCompletion
    ) -> LightningUpgradeStartViewController {
    let controller = LightningUpgradeStartViewController.makeFromStoryboard()
    controller.delegate = delegate
    controller.nextStep = nextStep
    return controller
  }

  private(set) weak var delegate: LightningUpgradeStartViewControllerDelegate!

  var exchangeRates: ExchangeRates = ExchangeRateManager().exchangeRates

  private var data: CNBCnlibTransactionData?
  var nextStep: CKCompletion = {}

  override func viewDidLoad() {
    super.viewDidLoad()
    styleInitialUI()
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .lightningUpgradeStart(.page)),
      (upgradeButton, .lightningUpgradeStart(.startUpgradeButton))
    ]
  }

  // to be called from owner when balance is provided
  func updateUI(withTransactionData data: CNBCnlibTransactionData?) {
    self.data = data

    // set activity indicator new distance
    let distance = (upgradeButton.frame.height / 2.0)
    activityIndicatorBottomConstraint.constant = -distance
    let duration: TimeInterval = 0.25

    UIView.animate(
      withDuration: duration,
      delay: 0.1,
      options: .curveEaseIn,
      animations: { self.view.layoutIfNeeded() },
      completion: { (_) in self.activityIndicator.isHidden = true }
    )

    // show selection view(s)
    UIView.animate(withDuration: 0.25,
                   delay: 0.1,
                   options: .curveEaseInOut,
                   animations: {
                    self.confirmNewWordsSelectionView.isHidden = false
                    self.showAmountViewIfNecessary(with: data)
                   },
                   completion: nil)
  }

  private func showAmountViewIfNecessary(with data: CNBCnlibTransactionData?) {
    guard let data = data, data.amount != 0 else { return }
    let fontSize: CGFloat = 12
    let btcAmount = NSDecimalNumber(integerAmount: Int(data.amount), currency: .BTC)
    let feeAmount = NSDecimalNumber(integerAmount: Int(data.feeAmount), currency: .BTC)
    self.exchangeRates = ExchangeRateManager().exchangeRates // update latest rates
    let amountConverter = CurrencyConverter(fromBtcTo: .USD, fromAmount: btcAmount, rates: exchangeRates)
    let feeConverter = CurrencyConverter(fromBtcTo: .USD, fromAmount: feeAmount, rates: exchangeRates)
    let fiatFormatter = FiatFormatter(currency: .USD, withSymbol: true)
    guard let amountString = fiatFormatter.string(fromDecimal: amountConverter.fiatAmount),
      let feeString = fiatFormatter.string(fromDecimal: feeConverter.fiatAmount) else { return }
    let fundTransferTitle = NSMutableAttributedString()
    fundTransferTitle.appendRegular("I understand that DropBit will be transferring my ", size: fontSize, color: .white, paragraphStyle: nil)
    fundTransferTitle.appendBold(
      "funds of \(amountString) with a transaction fee of \(feeString)",
      size: fontSize,
      color: .white,
      paragraphStyle: nil)
    fundTransferTitle.appendRegular(" to my upgraded wallet.", size: fontSize, color: .white, paragraphStyle: nil)
    confirmTransferFundsLabel.text = nil
    confirmTransferFundsLabel.attributedText = fundTransferTitle
    self.confirmTransferFundsView.isHidden = false
  }

  private func styleInitialUI() {
    lightningTitleLabel.textColor = .white
    lightningTitleLabel.font = .regular(18)
    detailLabel.textColor = .neonGreen
    detailLabel.font = .regular(14)

    upgradeButton.style = .lightningUpgrade(enabled: false)
    upgradeButton.setTitle("UPGRADE NOW", for: .normal)

    let templateImage = UIImage(imageLiteralResourceName: "checkboxCheck").withRenderingMode(.alwaysTemplate)

    confirmNewWordsCheckboxBackgroundView.backgroundColor = .white
    confirmNewWordsCheckmarkImage.isHidden = true
    confirmNewWordsCheckmarkImage.image = templateImage
    confirmNewWordsCheckmarkImage.tintColor = .deepPurple
    confirmNewWordsSelectionView.backgroundColor = .deepPurple
    confirmNewWordsSelectionView.isHidden = true
    confirmNewWordsSelectionView.applyCornerRadius(8)
    let fontSize: CGFloat = 12
    let newWordsTitle = NSMutableAttributedString()
    newWordsTitle.appendRegular("I understand that with this upgrade I will be getting a ", size: fontSize, color: .white, paragraphStyle: nil)
    newWordsTitle.appendBold("new set of 12 recovery words", size: fontSize, color: .white, paragraphStyle: nil)
    newWordsTitle.appendRegular(" to write down on paper and store safely.", size: fontSize, color: .white, paragraphStyle: nil)
    confirmNewWordsLabel.text = nil
    confirmNewWordsLabel.attributedText = newWordsTitle

    confirmTransferFundsCheckboxBackgroundView.backgroundColor = .white
    confirmTransferFundsCheckmarkImage.isHidden = true
    confirmTransferFundsCheckmarkImage.image = templateImage
    confirmTransferFundsCheckmarkImage.tintColor = .deepPurple
    confirmTransferFundsView.backgroundColor = .deepPurple
    confirmTransferFundsView.isHidden = true
    confirmTransferFundsView.applyCornerRadius(8)
    confirmTransferFundsLabel.text = nil
    confirmTransferFundsLabel.attributedText = nil

    let newWordsGesture = UITapGestureRecognizer(target: self, action: #selector(selectNewWordsOption))
    confirmNewWordsSelectionView.addGestureRecognizer(newWordsGesture)
    let transferFundsGesture = UITapGestureRecognizer(target: self, action: #selector(selectTransferFundsOption))
    confirmTransferFundsView.addGestureRecognizer(transferFundsGesture)
  }

  @objc
  private func selectNewWordsOption() {
    let hidden = confirmNewWordsCheckmarkImage.isHidden
    confirmNewWordsCheckmarkImage.isHidden = !hidden
    enableUpgradeIfPossible()
  }

  @objc
  private func selectTransferFundsOption() {
    let hidden = confirmTransferFundsCheckmarkImage.isHidden
    confirmTransferFundsCheckmarkImage.isHidden = !hidden
    enableUpgradeIfPossible()
  }

  private func enableUpgradeIfPossible() {
    let newWordsSelected = !confirmNewWordsCheckmarkImage.isHidden
    let transferSelected = !confirmTransferFundsCheckmarkImage.isHidden

    if (data?.amount ?? 0) == 0 && newWordsSelected {
      upgradeButton.style = .lightningUpgrade(enabled: true)
    } else if newWordsSelected && transferSelected {
      upgradeButton.style = .lightningUpgrade(enabled: true)
    } else {
      upgradeButton.style = .lightningUpgrade(enabled: false)
    }
  }

  @IBAction func showInfo(_ sender: UIButton) {
    delegate.viewControllerRequestedShowLightningUpgradeInfo(self)
  }

  @IBAction func upgradeNow(_ sender: UIButton) {
    delegate.viewControllerRequestedUpgradeAuthentication(self) {
      self.nextStep()
    }
  }
}
