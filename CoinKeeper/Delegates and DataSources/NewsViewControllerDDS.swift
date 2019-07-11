//
//  NewsViewControllerDDS.swift
//  DropBit
//
//  Created by Mitchell Malleo on 6/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import Charts
import Moya
import PromiseKit
import os.log

protocol NewsViewControllerDDSDelegate: class {
  func delegateDidRequestTableView() -> UITableView
  func delegateFinishedLoadingData()
  func delegateDidRequestUrl(_ url: URL)
}

class NewsViewControllerDDS: NSObject {

  enum CellIdentifier: Int {
    case price = 0
    case lineGraph = 1
    case timePeriod = 2
    case newsHeader = 3
    case article = 4
  }

  weak var delegate: NewsViewControllerDDSDelegate?

  private var currentTimePeriod: TimePeriodCell.Period = .daily
  let logger = OSLog(subsystem: "com.coinninja.coinkeeper.newsviewcontroller", category: "news_view_controller")

  var newsData: NewsData = NewsData() {
    didSet {
      delegate?.delegateDidRequestTableView().reloadData()
      delegate?.delegateFinishedLoadingData()
    }
  }

  func setupDataSet(coordinationDelegate: NewsViewControllerDelegate) {
    var newsData = NewsData()

    coordinationDelegate.viewControllerDidRequestNewsData(count: 100).then { articles -> Promise<[PriceSummaryResponse]> in
        newsData.articles = articles
        return coordinationDelegate.viewControllerDidRequestPriceDataFor(period: .daily)
      }.then { dailyPrice -> Promise<[PriceSummaryResponse]> in
        let day = self.configureDailyData(data: dailyPrice.reversed())
        newsData.dayPriceData = LineChartDataSet(values: day.data, label: nil)
        newsData.dayPriceResponse = day.response
        return coordinationDelegate.viewControllerDidRequestPriceDataFor(period: .monthly)
      }.then { monthlyPrice -> Promise<[PriceSummaryResponse]> in
        let monthlyData = self.configureMonthlyData(data: monthlyPrice.reversed())
        newsData.weeklyPriceData = LineChartDataSet(values: monthlyData.weekData, label: nil)
        newsData.weeklyPriceResponse = monthlyData.weekResponse
        newsData.monthlyPriceData = LineChartDataSet(values: monthlyData.monthData, label: nil)
        newsData.monthlyPriceResponse = monthlyData.monthResponse
        return coordinationDelegate.viewControllerDidRequestPriceDataFor(period: .allTime)
      }.done { allTimePrice in
        let allTimeData = self.configureAllTimeData(data: allTimePrice.reversed())
        newsData.allTimePriceData = LineChartDataSet(values: allTimeData.allTime, label: nil)
        newsData.allTimePriceResponse = allTimeData.allTimeResponse
        newsData.yearlyPriceData = LineChartDataSet(values: allTimeData.year, label: nil)
        newsData.yearlyPriceResponse = allTimeData.yearResponse
      }.catch(on: .main, policy: .allErrors) { error in
        os_log("News data failed: %@", log: self.logger, type: .error, error.localizedDescription)
      }.finally(on: .main) {
        newsData.currentPrice = self.newsData.currentPrice
        self.newsData = newsData
    }

  }

  private func configureMonthlyData(data: [PriceSummaryResponse]) ->
    (weekData: [ChartDataEntry], weekResponse: [PriceSummaryResponse],
    monthData: [ChartDataEntry], monthResponse: [PriceSummaryResponse]) {
      var weekData: [ChartDataEntry] = [], monthData: [ChartDataEntry] = []
      var weekResponse: [PriceSummaryResponse] = [], monthResponse: [PriceSummaryResponse] = []

      for (index, data) in data.enumerated() {
        guard index < 720 else { break }

        let chartData = ChartDataEntry(x: Double(index), y: data.average)

        if index <= 555 {
          monthData.append(chartData)
          monthResponse.append(data)
        } else {
          weekData.append(chartData)
          weekResponse.append(data)
          monthData.append(chartData)
          monthResponse.append(data)
        }
      }

      return (weekData: weekData, weekResponse: weekResponse, monthData: monthData, monthResponse: monthResponse)
  }

  private func configureDailyData(data: [PriceSummaryResponse]) -> (data: [ChartDataEntry], response: [PriceSummaryResponse]) {
    var dailyData: [ChartDataEntry] = [], responseData: [PriceSummaryResponse] = []

    for (index, data) in data.enumerated() {
      guard index < 1440 else { break }
      let chartData = ChartDataEntry(x: Double(index), y: data.average)

      dailyData.append(chartData)
      responseData.append(data)
    }

    return (data: dailyData, response: responseData)
  }

  private func configureAllTimeData(data: [PriceSummaryResponse]) ->
    (year: [ChartDataEntry], yearResponse: [PriceSummaryResponse],
    allTime: [ChartDataEntry], allTimeResponse: [PriceSummaryResponse]) {
      var yearData: [ChartDataEntry] = [], allTimeData: [ChartDataEntry] = []
      var yearResponse: [PriceSummaryResponse] = [], allTimeResponse: [PriceSummaryResponse] = []

      for (index, priceData) in data.enumerated() {
        let chartData = ChartDataEntry(x: Double(index), y: priceData.average)

        if index <= data.count - 365 {
          allTimeData.append(chartData)
          allTimeResponse.append(priceData)
        } else {
          yearData.append(chartData)
          yearResponse.append(priceData)
          allTimeResponse.append(priceData)
          allTimeData.append(chartData)
        }
      }

      return (year: yearData, yearResponse: yearResponse, allTime: allTimeData, allTimeResponse: allTimeResponse)
  }
}

extension NewsViewControllerDDS: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard indexPath.row > 2 else { return }

    if let url = URL(string: newsData.articles[indexPath.row - 2].link) {
      delegate?.delegateDidRequestUrl(url)
    }
  }
}

extension NewsViewControllerDDS: UITableViewDataSource {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    switch CellIdentifier(rawValue: indexPath.row) {
    case .price?:
      return 120
    case .lineGraph?:
      return 250
    case .timePeriod?:
      return 60
    case .newsHeader?:
      return 50
    default:
      return 135
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return CellIdentifier.newsHeader.rawValue + newsData.articles.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    var cell: UITableViewCell = UITableViewCell()

    switch CellIdentifier(rawValue: indexPath.row) {
    case .price?:
      if let priceCell = tableView.dequeueReusableCell(withIdentifier: PriceCell.reuseIdentifier, for: indexPath) as? PriceCell {
        priceCell.priceLabel.text = newsData.currentPrice
        priceCell.movement = newsData.getPriceMovement(currentTimePeriod)
        cell = priceCell
      }
    case .lineGraph?:
      if let lineGraphCell = tableView.dequeueReusableCell(withIdentifier: LineChartCell.reuseIdentifier, for: indexPath) as? LineChartCell {
        let lineChartData = LineChartData()
        let dataSet = newsData.getDataSetForTimePeriod(currentTimePeriod)
        dataSet.circleRadius = 0.0
        dataSet.lineWidth = 2.0
        dataSet.mode = .cubicBezier
        lineChartData.addDataSet(dataSet)
        lineGraphCell.data = lineChartData
        cell = lineGraphCell
      }
    case .timePeriod?:
      if let timePeriodCell = tableView.dequeueReusableCell(withIdentifier: TimePeriodCell.reuseIdentifier, for: indexPath) as? TimePeriodCell {
        timePeriodCell.delegate = self
        cell = timePeriodCell
      }
    case .newsHeader?:
      if let newsHeaderCell = tableView.dequeueReusableCell(withIdentifier: NewsTitleCell.reuseIdentifier, for: indexPath) as? NewsTitleCell {
        cell = newsHeaderCell
      }
    default:
      if let newsCell = tableView.dequeueReusableCell(withIdentifier: NewsArticleCell.reuseIdentifier, for: indexPath) as? NewsArticleCell,
        let article = newsData.articles[safe: indexPath.row - 2] {
        newsCell.titleLabel.text = article.title
        newsCell.sourceLabel.text = article.getFullSource()

        if let thumbnail = article.thumbnail, thumbnail.isNotEmpty {
          newsCell.imageURL = thumbnail
        } else {
          newsCell.source = NewsArticleResponse.Source(rawValue: article.source ?? NewsArticleResponse.Source.coinninja.rawValue)
        }

        cell = newsCell
      }
    }

    return cell
  }
}

extension NewsViewControllerDDS: TimePeriodCellDelegate {

  func timePeriodWasSelected(_ period: TimePeriodCell.Period) {
    currentTimePeriod = period
    delegate?.delegateDidRequestTableView().reloadData()
  }

}
