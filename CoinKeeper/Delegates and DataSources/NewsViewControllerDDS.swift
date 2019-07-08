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

protocol NewsViewControllerDDSDelegate: class {
  func delegateDidRequestTableView() -> UITableView
}

struct NewsData {
  var newsActionHandler: (URL) -> Void = { _ in }
  var articles: [NewsArticleResponse] = []
  var dayPriceData: LineChartDataSet = LineChartDataSet()
  var allTimePriceData: LineChartDataSet = LineChartDataSet()
  var yearlyPriceData: LineChartDataSet = LineChartDataSet()
  var monthlyPriceData: LineChartDataSet = LineChartDataSet()
  var weeklyPriceData: LineChartDataSet = LineChartDataSet()
  var dailyPriceData: LineChartDataSet = LineChartDataSet()
  var currentPrice: String = ""
  var priceData: LineChartDataSet = LineChartDataSet() //TODO: Set to current data set
}

class NewsViewControllerDDS: NSObject, UITableViewDelegate, UITableViewDataSource {

  enum CellIdentifier: Int {
    case price = 0
    case lineGraph = 1
    case timePeriod = 2
    case newsHeader = 3
    case article = 4
  }
  
  weak var delegate: NewsViewControllerDDSDelegate?

  var newsData: NewsData = NewsData() {
    didSet {
      delegate?.delegateDidRequestTableView().reloadData()
    }
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    switch CellIdentifier(rawValue: indexPath.row) {
    case .price?:
      return 90
    case .lineGraph?:
      return 250
    case .timePeriod?:
      return 30
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
        priceCell.movement = (usd: 1.43, percent: 0.3)
        cell = priceCell
      }
    case .lineGraph?:
      if let lineGraphCell = tableView.dequeueReusableCell(withIdentifier: LineChartCell.reuseIdentifier, for: indexPath) as? LineChartCell {
        var lineChartData = LineChartData()
        lineChartData.addDataSet(newsData.priceData)
        lineGraphCell.data = lineChartData
        cell = lineGraphCell
      }
    case .timePeriod?:
      if let timePeriodCell = tableView.dequeueReusableCell(withIdentifier: TimePeriodCell.reuseIdentifier, for: indexPath) as? TimePeriodCell {
        //TODO: Assign delegate for selection of different data sets
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
        newsCell.sourceLabel.text = article.source

        if article.thumbnail != "" {
          newsCell.imageURL = article.thumbnail ?? ""
        } else {
          newsCell.source = NewsArticleResponse.Source(rawValue: article.source) ?? .btc
        }

        cell = newsCell
      }
    }

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard indexPath.row > 2 else { return }

    if let url = URL(string: newsData.articles[indexPath.row - 2].link) {
      newsData.newsActionHandler(url)
    }
  }
}
