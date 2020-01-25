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

  private let newsCellIndexOffset = 4

  enum CellIdentifier: Int {
    case price = 0
    case lineGraph = 1
    case timePeriod = 2
    case newsHeader = 3
    case article = 4
  }

  weak var delegate: NewsViewControllerDDSDelegate?

  private var currentTimePeriod: TimePeriod = .daily

  var newsData: NewsData = NewsData() {
    didSet {
      delegate?.delegateRefreshNews()
    }
  }

  init(delegate: NewsViewControllerDDSDelegate) {
    self.delegate = delegate
  }

  func setupDataSet(coordinationDelegate: NewsViewControllerDelegate) {
    let newsData = NewsData()

    coordinationDelegate.viewControllerDidRequestNewsData(count: 100)
      .then { articles -> Promise<[PriceSummaryResponse]> in
        newsData.articles = articles
        return coordinationDelegate.viewControllerDidRequestPriceDataFor(period: .daily)
      }.then { dailyPrice -> Promise<[PriceSummaryResponse]> in
        newsData.configureDailyData(data: dailyPrice)
        return coordinationDelegate.viewControllerDidRequestPriceDataFor(period: .monthly)
      }.then { monthlyPrice -> Promise<[PriceSummaryResponse]> in
        newsData.configureWeekAndMonthData(data: monthlyPrice.reversed())
        return coordinationDelegate.viewControllerDidRequestPriceDataFor(period: .allTime)
      }.done { allTimePrice in
        newsData.configureYearAndAllTimeData(data: allTimePrice.reversed())
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
        newsCell.load(article: article) { [weak newsCell] image in
          article.image = image
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

  func timePeriodWasSelected(_ period: TimePeriod) {
    currentTimePeriod = period
    delegate?.delegateRefreshNews()
  }

}
