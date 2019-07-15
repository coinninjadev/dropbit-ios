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
  func delegateErrorLoadingData()
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

  var newsData: NewsData = NewsData() {
    didSet {
      delegate?.delegateDidRequestTableView().reloadData()
    }
  }

  func setupDataSet(coordinationDelegate: NewsViewControllerDelegate) {
    var newsData = NewsData()

    coordinationDelegate.viewControllerDidRequestNewsData(count: 100)
      .then { articles -> Promise<[PriceSummaryResponse]> in
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
        self.delegate?.delegateFinishedLoadingData()
      }.catch(on: .main, policy: .allErrors) { error in
        self.delegate?.delegateErrorLoadingData()
        os_log("News data failed: %@", log: self.logger, type: .error, error.localizedDescription)
      }.finally(on: .main) {
        newsData.currentPrice = self.newsData.currentPrice
        self.newsData = newsData
    }

  }

  struct WeekMonthChartData {
    let weekData: [ChartDataEntry]
    let weekResponse: [PriceSummaryResponse]
    let monthData: [ChartDataEntry]
    let monthResponse: [PriceSummaryResponse]
  }

  private func configureMonthlyData(data: [PriceSummaryResponse]) -> WeekMonthChartData {
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

    let data = WeekMonthChartData(weekData: weekData, weekResponse: weekResponse, monthData: monthData, monthResponse: monthResponse)
    return data
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

  struct AllTimePriceChartData {
    let year: [ChartDataEntry]
    let yearResponse: [PriceSummaryResponse]
    let allTime: [ChartDataEntry]
    let allTimeResponse: [PriceSummaryResponse]
  }

  private func configureAllTimeData(data: [PriceSummaryResponse]) -> AllTimePriceChartData {
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

    let data = AllTimePriceChartData(year: yearData, yearResponse: yearResponse, allTime: allTimeData, allTimeResponse: allTimeResponse)
    return data
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
      let priceCell = tableView.dequeue(PriceCell.self, for: indexPath)
      priceCell.priceLabel.text = newsData.currentPrice
      priceCell.movement = newsData.getPriceMovement(currentTimePeriod)
      cell = priceCell
    case .lineGraph?:
      let lineGraphCell = tableView.dequeue(LineChartCell.self, for: indexPath)
      let lineChartData = LineChartData()
      let dataSet = newsData.getDataSetForTimePeriod(currentTimePeriod)
      dataSet.circleRadius = 0.0
      dataSet.lineWidth = 2.0
      dataSet.mode = .cubicBezier
      lineChartData.addDataSet(dataSet)
      lineGraphCell.data = lineChartData
      cell = lineGraphCell
    case .timePeriod?:
      let timePeriodCell = tableView.dequeue(TimePeriodCell.self, for: indexPath)
      timePeriodCell.delegate = self
      cell = timePeriodCell
    case .newsHeader?:
      cell = tableView.dequeue(NewsTitleCell.self, for: indexPath)
    default:
      let newsCell = tableView.dequeue(NewsArticleCell.self, for: indexPath)
      if let article = newsData.articles[safe: indexPath.row - 2] {
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
