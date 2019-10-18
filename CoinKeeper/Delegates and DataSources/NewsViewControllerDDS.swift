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

protocol NewsViewControllerDDSDelegate: class {
  func delegateRefreshNews()
  func delegateFinishedLoadingData()
  func delegateErrorLoadingData()
  func delegateDidRequestUrl(_ url: URL)
}

class NewsViewControllerDDS: NSObject {

  /*
   Monthly endpoint of price is broken down by hours
   Average of 30 days times 24 hours = 720
   720 hours minus a weeks worth of hours (7 x 24 = 168) is 552
  */
  lazy var weekDataSourceOffset: Int = {
    let hoursInWeek = 168
    return monthlyDataSourceOffset - hoursInWeek
  }()

  lazy var monthlyDataSourceOffset: Int = {
    let daysInMonth = 30, hoursInWeek = 24
    return daysInMonth * hoursInWeek
  }()

  lazy var dailyDataSourceOffset: Int = {
    let minutesInHour = 60, hoursInDay = 24
    return minutesInHour * hoursInDay
  }()

  private let newsCellIndexOffset = 4

  var yearDataSourceOffset: Int {
    return 365
  }

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
      delegate?.delegateRefreshNews()
    }
  }

  init(delegate: NewsViewControllerDDSDelegate) {
    self.delegate = delegate
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
        let monthlyData = self.configureWeekAndMonthData(data: monthlyPrice.reversed())
        newsData.weeklyPriceData = LineChartDataSet(values: monthlyData.weekData, label: nil)
        newsData.weeklyPriceResponse = monthlyData.weekResponse
        newsData.monthlyPriceData = LineChartDataSet(values: monthlyData.monthData, label: nil)
        newsData.monthlyPriceResponse = monthlyData.monthResponse
        return coordinationDelegate.viewControllerDidRequestPriceDataFor(period: .allTime)
      }.done { allTimePrice in
        let allTimeData = self.configureYearAndAllTimeData(data: allTimePrice.reversed())
        newsData.allTimePriceData = LineChartDataSet(values: allTimeData.allTime, label: nil)
        newsData.allTimePriceResponse = allTimeData.allTimeResponse
        newsData.yearlyPriceData = LineChartDataSet(values: allTimeData.year, label: nil)
        newsData.yearlyPriceResponse = allTimeData.yearResponse
        self.delegate?.delegateFinishedLoadingData()
      }.catch(on: .main, policy: .allErrors) { error in
        self.delegate?.delegateErrorLoadingData()
        log.error("News data failed: \(error.localizedDescription)")
      }.finally(on: .main) {
        newsData.currentPrice = self.newsData.currentPrice
        self.newsData = newsData
        self.delegate?.delegateRefreshNews()
    }

  }

  struct WeekMonthChartData {
    let weekData: [ChartDataEntry]
    let weekResponse: [PriceSummaryResponse]
    let monthData: [ChartDataEntry]
    let monthResponse: [PriceSummaryResponse]
  }

  private func configureWeekAndMonthData(data: [PriceSummaryResponse]) -> WeekMonthChartData {
    let monthStartIndex = max(0, data.count - monthlyDataSourceOffset), monthResponse = Array(data[monthStartIndex..<data.count])
    let weekStartIndex = max(0, monthResponse.count - weekDataSourceOffset)
    let weekResponseStartIndex = max(0, monthResponse.count - weekStartIndex)
    let weekResponse = Array(monthResponse[weekResponseStartIndex..<monthResponse.count])
    let weekData = weekResponse.enumerated().map { index, element in return ChartDataEntry(x: Double(index), y: element.average) }
    let monthData = monthResponse.enumerated().map { index, element in return ChartDataEntry(x: Double(index), y: element.average) }

    return WeekMonthChartData(weekData: weekData, weekResponse: weekResponse, monthData: monthData, monthResponse: monthResponse)
  }

  private func configureDailyData(data: [PriceSummaryResponse]) -> (data: [ChartDataEntry], response: [PriceSummaryResponse]) {
    let startIndex = max(0, data.count - dailyDataSourceOffset)
    let responseData = Array(data[startIndex..<data.count]).enumerated().compactMap { $0 % 5 == 0 ? $1 : nil }
    let dailyData = responseData.enumerated().map { index, element in return ChartDataEntry(x: Double(index), y: element.average) }

    return (data: dailyData, response: responseData)
  }

  struct AllTimePriceChartData {
    let year: [ChartDataEntry]
    let yearResponse: [PriceSummaryResponse]
    let allTime: [ChartDataEntry]
    let allTimeResponse: [PriceSummaryResponse]
  }

  private func configureYearAndAllTimeData(data: [PriceSummaryResponse]) -> AllTimePriceChartData {
    let yearStartIndex = max(0, data.count - yearDataSourceOffset), yearResponse = Array(data[yearStartIndex..<data.count])
    let yearData = yearResponse.enumerated().map { index, element in return ChartDataEntry(x: Double(index), y: element.average) }
    let allTimeResponseData = Array(data[0..<data.count]).enumerated().compactMap { $0 % 5 == 0 ? $1 : nil }
    let allTimeData = allTimeResponseData.enumerated().map { index, element in return ChartDataEntry(x: Double(index), y: element.average) }

    return AllTimePriceChartData(year: yearData, yearResponse: yearResponse, allTime: allTimeData, allTimeResponse: allTimeResponseData)
  }
}

extension NewsViewControllerDDS: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard indexPath.row >= newsCellIndexOffset else { return }

    if let url = URL(string: newsData.articles[indexPath.row - newsCellIndexOffset].link) {
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
      priceCell.priceLabel.text = newsData.displayPrice
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
      let index = indexPath.row - newsCellIndexOffset
      if var article = newsData.articles[safe: index] {
        newsCell.load(article: article) { [weak newsCell] imageData in
          article.imageData = imageData
          self.newsData.articles[index] = article
          newsCell?.load(article: article) { _ in }
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
    delegate?.delegateRefreshNews()
  }

}
