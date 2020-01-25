//
//  TodayView.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 1/17/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import Charts

class TodayView: UIView {

  let openAppButton = UIButton(frame: .zero)
  private let bitcoinImageView = UIImageView()
  private let bitcoinTitleLabel = UILabel()
  private let bitcoinDetailLabel = UILabel()
  private let priceTitleLabel = UILabel()
  private let priceDetailLabel = UILabel()
  var dataUnavailableLabel = UILabel() {
    willSet {
      newValue.text = "Data Unavailable"
    }
  }

  private let bitcoinStackView = UIStackView()
  private let priceStackView = UIStackView()

  var newsData: NewsData? {
    didSet {
      updateUI(viewModel: newsData)
    }
  }

  private var movement: (gross: Double, percentage: Double)? {
    didSet {
      guard let movement = movement, movement.gross != 0, movement.percentage != 0 else { return }
      let percentageNumber = NSNumber(value: movement.percentage)
      let percentageString = "\(NumberFormatter.percentageFormatter.string(from: percentageNumber) ?? "")%"
      let displayString: String =  movement.gross > 0 ? "▲ \(percentageString)" : "▼ \(percentageString)"

      if movement.gross > 0 {
        priceTitleLabel.textColor = .widgetGreen
        priceDetailLabel.textColor = .widgetGreen
      } else {
        priceTitleLabel.textColor = .widgetRed
        priceDetailLabel.textColor = .widgetRed
      }

      priceDetailLabel.text = displayString
    }
  }

  init() {
    super.init(frame: .zero)
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    bitcoinImageView.image = UIImage(named: "bitcoinImage")
    bitcoinImageView.contentMode = .scaleAspectFit
    addSubview(bitcoinImageView)

    bitcoinStackView.axis = .vertical
    priceStackView.axis = .vertical

    bitcoinTitleLabel.text = "Bitcoin"
    bitcoinTitleLabel.font = .semiBold(16)
    bitcoinStackView.addArrangedSubview(bitcoinTitleLabel)

    bitcoinDetailLabel.text = "BTC"
    bitcoinDetailLabel.font = .regular(12)
    bitcoinDetailLabel.textColor = .widgetGray
    bitcoinStackView.addArrangedSubview(bitcoinDetailLabel)

    priceTitleLabel.textAlignment = .right
    priceTitleLabel.font = .bold(17)
    priceStackView.addArrangedSubview(priceTitleLabel)

    priceDetailLabel.font = .regular(12)
    priceDetailLabel.textAlignment = .right
    priceStackView.addArrangedSubview(priceDetailLabel)

    addSubview(bitcoinStackView)
    addSubview(priceStackView)
    addSubview(dataUnavailableLabel)
    addSubview(openAppButton)

    setupConstraints()
  }

  private func updateUI(viewModel: NewsData?) {
    if let newsData = viewModel {
      priceTitleLabel.text = newsData.displayPrice
      movement = newsData.getPriceMovement(.daily)
      dataUnavailableLabel.isHidden = true
      bitcoinStackView.arrangedSubviews.forEach { $0.isHidden = false }
      priceStackView.arrangedSubviews.forEach { $0.isHidden = false }
    } else {
      dataUnavailableLabel.isHidden = false
      bitcoinStackView.arrangedSubviews.forEach { $0.isHidden = true }
      priceStackView.arrangedSubviews.forEach { $0.isHidden = true }
    }
  }

  private func setupConstraints() {
    bitcoinImageView.translatesAutoresizingMaskIntoConstraints = false
    bitcoinImageView.heightAnchor.constraint(equalToConstant: 27).isActive = true
    bitcoinImageView.widthAnchor.constraint(equalToConstant: 27).isActive = true
    bitcoinImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30).isActive = true
    bitcoinImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

    bitcoinStackView.translatesAutoresizingMaskIntoConstraints = false
    bitcoinStackView.leadingAnchor.constraint(equalTo: bitcoinImageView.trailingAnchor, constant: 8).isActive = true
    bitcoinStackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

    priceStackView.translatesAutoresizingMaskIntoConstraints = false
    priceStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30).isActive = true
    priceStackView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

    dataUnavailableLabel.translatesAutoresizingMaskIntoConstraints = false
    dataUnavailableLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    dataUnavailableLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

    constrain(to: openAppButton)
  }

}
