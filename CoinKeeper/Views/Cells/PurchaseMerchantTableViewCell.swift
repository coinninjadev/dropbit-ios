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
  func actionButtonWasPressed(type: MerchantCallToActionStyle, url: String)
  func tooltipButtonWasPressed(with url: URL)
}

class PurchaseMerchantTableViewCell: UITableViewCell, FetchImageType {

  @IBOutlet var logoImageView: UIImageView!
  @IBOutlet var containerView: UIView!
  @IBOutlet var tooltipButton: UIButton!
  @IBOutlet var stackView: UIStackView!
  @IBOutlet var attributeStackView: UIStackView!
  var actionButton: PrimaryActionButton = PrimaryActionButton()
  var buyWithApplePayButton: PKPaymentButton = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)

  private var viewModel: MerchantResponse?
  weak var delegate: PurchaseMerchantTableViewCellDelegate?
  var dataTask: URLSessionDataTask?

  override func prepareForReuse() {
    super.prepareForReuse()
    dataTask = nil
    logoImageView.image = nil

    for view in attributeStackView.arrangedSubviews {
      attributeStackView.removeArrangedSubview(view)
      view.removeFromSuperview()
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

  func load(with model: MerchantResponse) {
    viewModel = model

    fetchImage(at: model.image) { [weak self] image in
      self?.logoImageView.image = image
    }

    tooltipButton.isHidden = model.tooltip == nil

    for attribute in model.attributes {
      addAttributeView(with: attribute)
    }

    switch model.cta.actionStyle {
    case .device:
      buyWithApplePayButton.isHidden = false
      actionButton.isHidden = true
    default:
      buyWithApplePayButton.isHidden = true
      actionButton.isHidden = false
    }

    configureButtons(with: model.cta.actionStyle)
  }

  private func setupButtons() {
    actionButton.translatesAutoresizingMaskIntoConstraints = false
    actionButton.heightAnchor.constraint(equalToConstant: 51).isActive = true
    actionButton.addTarget(self, action: #selector(actionButtonWasTouched), for: .touchUpInside)

    buyWithApplePayButton.addTarget(self, action: #selector(applePayButtonWasTouched), for: .touchUpInside)
    buyWithApplePayButton.translatesAutoresizingMaskIntoConstraints = false
    buyWithApplePayButton.heightAnchor.constraint(equalToConstant: 51).isActive = true
  }

  private func configureButtons(with buyType: MerchantCallToActionStyle) {
    let font = UIFont.medium(18)
    switch buyType {
    case .device:
      stackView.removeArrangedSubview(actionButton)
      stackView.addArrangedSubview(buyWithApplePayButton)
    case .atm:
      let mapPinImage = UIImage(imageLiteralResourceName: "mapPin")
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
      let attributes: StringAttributes = [
        .font: font,
        .foregroundColor: UIColor.white
      ]
      actionButton.style = .neonGreen
      actionButton.setAttributedTitle(NSAttributedString(string: "BUY NOW", attributes: attributes), for: .normal)
      actionButton.setImage(nil, for: .normal)
      stackView.removeArrangedSubview(buyWithApplePayButton)
      stackView.addArrangedSubview(actionButton)
    }
  }

  private func addAttributeView(with attribute: MerchantAttributeResponse) {
    let view = MerchantAttributeView(frame: .zero)
    view.delegate = self
    view.load(with: attribute)
    attributeStackView.addArrangedSubview(view)
  }

  @IBAction func tooltipButtonWasTouched() {
    guard let tooltipUrl = viewModel?.tooltip, let url = URL(string: tooltipUrl) else { return }
    delegate?.tooltipButtonWasPressed(with: url)
  }

  @objc func actionButtonWasTouched() {
    merchantCallToActionWasPressed()
  }

  @objc func applePayButtonWasTouched() {
    if PKPaymentAuthorizationController.canMakePayments() {
      merchantCallToActionWasPressed()
    } else {
      PKPassLibrary().openPaymentSetup()
    }
  }

  private func merchantCallToActionWasPressed() {
    guard let viewModel = viewModel else { return }
    delegate?.actionButtonWasPressed(type: viewModel.cta.actionStyle,
                                     url: viewModel.cta.link)
  }

}

extension PurchaseMerchantTableViewCell: MerchantAttributeViewDelegate {

  func attributeViewWasTouched(with url: URL) {
    delegate?.attributeLinkWasTouched(with: url)
  }
}
