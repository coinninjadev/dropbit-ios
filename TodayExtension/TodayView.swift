//
//  TodayView.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 1/17/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import NotificationCenter
import UIKit
import Charts

class TodayView: UIView {

  let openAppButton = UIButton(frame: .zero)
  private let bitcoinImageView = UIImageView()
  private let bitcoinTitleLabel = UILabel()
  private let bitcoinDetailLabel = UILabel()
  private let priceTitleLabel = UILabel()
  private let priceDetailLabel = UILabel()
  private let chart: LineChartView = LineChartView()
  private let bitcoinStackView = UIStackView()
  private let priceStackView = UIStackView()
  private let activityIndicator = UIActivityIndicatorView()

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

      priceDetailLabel.attributedText = NSMutableAttributedString.space(displayString, spacing: 1)
    }
  }

  lazy private var extendedConstraints: [NSLayoutConstraint] = {
    let bitcoinTopAnchor = NSLayoutConstraint(item: bitcoinStackView, attribute: .top, relatedBy: .equal,
                                                 toItem: self, attribute: .top, multiplier: 1.0, constant: 10.0)
    let priceTopAnchor = NSLayoutConstraint(item: priceStackView, attribute: .top, relatedBy: .equal,
                                               toItem: self, attribute: .top, multiplier: 1.0, constant: 10.0)
    return [bitcoinTopAnchor, priceTopAnchor]
  }()

  lazy private var compactConstraints: [NSLayoutConstraint] = {
    let bitcoinCenterAnchor = NSLayoutConstraint(item: bitcoinStackView, attribute: .centerY, relatedBy: .equal,
                                                 toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0)
    let priceCenterAnchor = NSLayoutConstraint(item: priceStackView, attribute: .centerY, relatedBy: .equal,
                                               toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0)
    return [bitcoinCenterAnchor, priceCenterAnchor]
  }()

  init() {
    super.init(frame: .zero)
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    activityIndicator.hidesWhenStopped = true

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

    priceDetailLabel.font = .semiBold(12)
    priceDetailLabel.textAlignment = .right
    priceStackView.addArrangedSubview(priceDetailLabel)

    chart.leftAxis.enabled = false
    chart.rightAxis.enabled = false
    chart.xAxis.enabled = false
    chart.pinchZoomEnabled = false
    chart.legend.form = .none
    chart.doubleTapToZoomEnabled = false
    chart.data = LineChartData()

    addSubview(bitcoinStackView)
    addSubview(priceStackView)
    addSubview(chart)
    addSubview(activityIndicator)
    addSubview(openAppButton)

    setupSharedConstraints()
    setupConstraints(with: .expanded)
    subviews.forEach { $0.isHidden = true }
    activityIndicator.isHidden = false
    activityIndicator.startAnimating()
  }

  private func updateUI(viewModel: NewsData?) {
    if let newsData = viewModel {
      priceTitleLabel.attributedText = NSMutableAttributedString.space(newsData.displayPrice, spacing: 0.5)
      movement = newsData.getPriceMovement(.daily)
      let lineChartData = LineChartData()
      let dataSet = newsData.getDataSetForTimePeriod(.daily)
      dataSet.circleRadius = 0
      dataSet.lineWidth = 2
      dataSet.mode = .horizontalBezier
      lineChartData.addDataSet(dataSet)

      if let lastPoint = dataSet.entries.last {
        let circleDataSet = LineChartDataSet(entries: [lastPoint], label: nil)
        circleDataSet.circleRadius = 3.5
        circleDataSet.lineWidth = 2
        circleDataSet.mode = .horizontalBezier
        lineChartData.addDataSet(circleDataSet)
      }

      chart.data = lineChartData
      subviews.forEach { $0.isHidden = false }
    } else {
      subviews.forEach { $0.isHidden = true }
    }

    activityIndicator.isHidden = true
    activityIndicator.stopAnimating()
  }

  func updateLayout(with mode: NCWidgetDisplayMode) {
    setupConstraints(with: mode)
  }

  private func setupConstraints(with mode: NCWidgetDisplayMode) {
    switch mode {
    case .compact:
      chart.isHidden = true
      setupConstraintForCompactView()
    case .expanded:
      chart.isHidden = false
      setupConstraintsForExpandedView()
    default:
      break
    }
  }

  private func setupSharedConstraints() {
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

    bitcoinImageView.translatesAutoresizingMaskIntoConstraints = false
    bitcoinImageView.heightAnchor.constraint(equalToConstant: 27).isActive = true
    bitcoinImageView.widthAnchor.constraint(equalToConstant: 27).isActive = true
    bitcoinImageView.centerYAnchor.constraint(equalTo: priceStackView.centerYAnchor).isActive = true
    bitcoinImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 30).isActive = true

    bitcoinStackView.translatesAutoresizingMaskIntoConstraints = false
    bitcoinStackView.leadingAnchor.constraint(equalTo: bitcoinImageView.trailingAnchor, constant: 8).isActive = true

    priceStackView.translatesAutoresizingMaskIntoConstraints = false
    priceStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -30).isActive = true

    chart.translatesAutoresizingMaskIntoConstraints = false
    chart.topAnchor.constraint(equalTo: bitcoinStackView.bottomAnchor, constant: 10).isActive = true
    chart.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -10).isActive = true
    chart.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
    chart.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

    constrain(to: openAppButton)
  }

  private func setupConstraintForCompactView() {
    NSLayoutConstraint.activate(compactConstraints)
    NSLayoutConstraint.deactivate(extendedConstraints)
  }

  private func setupConstraintsForExpandedView() {
    NSLayoutConstraint.deactivate(compactConstraints)
    NSLayoutConstraint.activate(extendedConstraints)
  }

}
