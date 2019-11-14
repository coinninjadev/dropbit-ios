//
//  PurchaseMerchantTableViewCell.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import PassKit
import Moya

protocol PurchaseMerchantTableViewCellDelegate: AnyObject {
  func attributeLinkWasTouched(with url: URL)
  func actionButtonWasPressed(with type: BuyMerchantBuyType, url: String)
  func tooltipButtonWasPressed(with url: URL)
}

class PurchaseMerchantTableViewCell: UITableViewCell, FetchImageType {

  @IBOutlet var logoImageView: UIImageView!
  @IBOutlet var containerView: UIView!
  @IBOutlet var tooltipButton: UIButton!
  @IBOutlet var stackView: UIStackView!
  @IBOutlet var attributeStackView: UIStackView!
  var actionButton: PrimaryActionButton!
  var buyWithApplePayButton: PKPaymentButton!

  private var viewModel: BuyMerchantResponse?
  weak var delegate: PurchaseMerchantTableViewCellDelegate?
  var dataTask: URLSessionDataTask?

  override func prepareForReuse() {
    super.prepareForReuse()
    dataTask = nil
    logoImageView.image = nil

    for view in attributeStackView.arrangedSubviews {
      attributeStackView.removeArrangedSubview(view)
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    selectionStyle = .none
    backgroundColor = .lightGrayBackground
    containerView.backgroundColor = .lightGrayBackground
    containerView.applyCornerRadius(10)
    containerView.layer.borderWidth = 1
    containerView.layer.borderColor = UIColor.mediumGrayBorder.cgColor
    setupButtons()
  }

  func load(with model: BuyMerchantResponse) {
    viewModel = model

    //fetchImage(at: model.imageUrl) { [weak self] image in
    logoImageView.image = model.image
    //}

    actionButton.addTarget(self, action: #selector(actionButtonWasTouched), for: .touchUpInside)
    tooltipButton.isHidden = model.tooltipUrl == nil

    for attribute in model.attributes {
      addAttributeView(with: attribute)
    }

    configureButtons(with: model.buyType)
  }

  private func setupButtons() {
    actionButton = PrimaryActionButton()
    actionButton.translatesAutoresizingMaskIntoConstraints = false
    actionButton.heightAnchor.constraint(equalToConstant: 51).isActive = true

    let button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
    button.addTarget(self, action: #selector(applePayButtonWasTouched), for: .touchUpInside)
    buyWithApplePayButton = button
    buyWithApplePayButton.translatesAutoresizingMaskIntoConstraints = false
    buyWithApplePayButton.heightAnchor.constraint(equalToConstant: 51).isActive = true
  }

  private func configureButtons(with buyType: BuyMerchantBuyType) {
    switch buyType {
    case .device:
      stackView.removeArrangedSubview(actionButton)
      stackView.addArrangedSubview(buyWithApplePayButton)
    case .atm:
      let mapPinImage = UIImage(imageLiteralResourceName: "mapPin")
      let font = UIFont.medium(18)
      let attributes: StringAttributes = [
        .font: font,
        .foregroundColor: UIColor.white
      ]

      let atmAttributedString = NSAttributedString(
        image: mapPinImage,
        fontDescender: font.descender,
        imageSize: CGSize(width: 13, height: 20)) + "  " + NSAttributedString(string: "FIND BITCOIN ATM",
                                                                              attributes: attributes)
      actionButton.setAttributedTitle(atmAttributedString, for: .normal)
      actionButton.style = .standard
      stackView.removeArrangedSubview(buyWithApplePayButton)
      stackView.addArrangedSubview(actionButton)
    case .default:
      actionButton.style = .green
      actionButton.setAttributedTitle(NSAttributedString(string: "BUY NOW"), for: .normal)
      actionButton.setImage(nil, for: .normal)
      stackView.removeArrangedSubview(buyWithApplePayButton)
      stackView.addArrangedSubview(actionButton)
    }
  }

  private func addAttributeView(with attribute: BuyMerchantAttribute) {
    let view = BuyMerchantAttributeView(frame: .zero)
    view.delegate = self
    view.load(with: attribute)
    attributeStackView.addArrangedSubview(view)
  }

  @IBAction func tooltipButtonWasTouched() {
    guard let viewModel = viewModel, let url = URL(string: viewModel.actionUrl) else { return }
    delegate?.tooltipButtonWasPressed(with: url)
  }

  @objc func actionButtonWasTouched() {
    guard let viewModel = viewModel else { return }
    delegate?.actionButtonWasPressed(with: viewModel.buyType, url: viewModel.actionUrl)
  }

  @objc func applePayButtonWasTouched() {
    if PKPaymentAuthorizationController.canMakePayments() {
      guard let viewModel = viewModel else { return }
      delegate?.actionButtonWasPressed(with: viewModel.buyType, url: viewModel.actionUrl)
    } else {
      PKPassLibrary().openPaymentSetup()
    }
  }

}

extension PurchaseMerchantTableViewCell: BuyMerchantAttributeViewDelegate {

  func attributeViewWasTouched(with url: URL) {
    delegate?.attributeLinkWasTouched(with: url)
  }
}
