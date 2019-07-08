//
//  NewsViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import Charts
import PromiseKit

protocol NewsViewControllerDelegate: ViewControllerDismissable {
  func viewControllerDidRequestNewsData(count: Int) -> Promise<[NewsArticleResponse]>
  func viewControllerDidRequestPriceDataFor(period: PricePeriod) -> Promise<[PriceSummaryResponse]>
}

class NewsViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var closeButton: UIButton!
  @IBOutlet var tableView: UITableView!
  @IBOutlet var priceLabel: UILabel! {
    didSet {
      priceLabel.textColor = .darkGrayText
      priceLabel.font = .regular(15)
    }
  }

  private lazy var formatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    formatter.plusSign = "+"
    formatter.minusSign = "-"
    formatter.locale = Locale.current
    formatter.usesGroupingSeparator = true
    formatter.numberStyle = .currency
    return formatter
  }()

  private var newsViewControllerDDS: NewsViewControllerDDS?

  lazy var updateRatesRequest: ExchangeRatesRequest = { [weak self] rates in
    let value = rates[.USD] as NSNumber?
    self?.currentPrice = self?.formatter.string(from: value ?? 0.0)
    self?.priceLabel.text = self?.currentPrice
    self?.tableView.reloadData()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  @IBAction func closeButtonWasTouched() {
    dismiss(animated: true, completion: nil)
  }

  var coordinationDelegate: NewsViewControllerDelegate? {
    return generalCoordinationDelegate as? NewsViewControllerDelegate
  }

  var currentPrice: String?

  override var generalCoordinationDelegate: AnyObject? {
    didSet {
      currencyValueManager = generalCoordinationDelegate as? CurrencyValueDataSourceType
    }
  }

  var dayDataSet: LineChartData?
  var weekTimeSet: LineChartData?
  var monthlyDataSet: LineChartData?
  var yearlyDataSet: LineChartData?
  var allTimeDataSet: LineChartData?

  var dataToShow: LineChartData?
  var articles: [NewsArticleResponse] = []

  weak var currencyValueManager: CurrencyValueDataSourceType?

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.registerNib(cellType: PriceCell.self)
    tableView.registerNib(cellType: TimePeriodCell.self)
    tableView.registerNib(cellType: NewsTitleCell.self)
    tableView.registerNib(cellType: LineChartCell.self)
    tableView.registerNib(cellType: NewsArticleCell.self)

    tableView.delegate = newsViewControllerDDS
    tableView.dataSource = newsViewControllerDDS
    tableView.isHidden = true
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.backgroundColor = .lightGrayBackground

    CKNotificationCenter.subscribe(self, [.didUpdateExchangeRates: #selector(refreshDisplayedPrice)])
    currencyValueManager?.latestExchangeRates(responseHandler: updateRatesRequest)

    setupDataSet()
  }

  private func setupDataSet() {
    var newsData = NewsData()
    guard let coordinationDelegate = coordinationDelegate else {
      newsViewControllerDDS?.newsData = newsData
      return
    }
    
    coordinationDelegate.viewControllerDidRequestNewsData(count: 10).then { articles -> Promise<[PriceSummaryResponse]> in
      newsData.articles = articles
      return coordinationDelegate.viewControllerDidRequestPriceDataFor(period: .daily)
    }.then { dailyPrice -> Promise<[PriceSummaryResponse]> in
      newsData.dailyPriceData = LineChartDataSet(values: self.configureDailyData(data: dailyPrice), label: nil)
      return coordinationDelegate.viewControllerDidRequestPriceDataFor(period: .monthly)
    }.then { monthlyPrice -> Promise<[PriceSummaryResponse]> in
      let monthlyData = self.configureMonthlyData(data: monthlyPrice)
      newsData.weeklyPriceData = LineChartDataSet(values: monthlyData.week, label: nil)
      newsData.monthlyPriceData = LineChartDataSet(values: monthlyData.month, label: nil)
      return coordinationDelegate.viewControllerDidRequestPriceDataFor(period: .allTime)
    }.done { allTimePrice in
      let allTimeData = self.configureAllTimeData(data: allTimePrice)
      newsData.allTimePriceData = LineChartDataSet(values: allTimeData.allTime, label: nil)
      newsData.yearlyPriceData = LineChartDataSet(values: allTimeData.year, label: nil)
      self.newsViewControllerDDS?.newsData = newsData
    }
  }
  
  private func configureMonthlyData(data: [PriceSummaryResponse]) -> (week: [ChartDataEntry], month: [ChartDataEntry]) {
    var weekData: [ChartDataEntry] = [], monthData: [ChartDataEntry] = []
    
    for (index, data) in data.enumerated() {
      guard index < 720 else { break }
      
      let data = ChartDataEntry(x: Double(index), y: data.average)
      
      if (index <= 168) {
        weekData.append(data)
        monthData.append(data)
      } else {
        monthData.append(data)
      }
    }
    
    return (week: weekData, month: monthData)
  }
  
  private func configureDailyData(data: [PriceSummaryResponse]) -> [ChartDataEntry] {
    var dailyData: [ChartDataEntry] = []
    
    for (index, data) in data.enumerated() {
      guard index < 1440 else { break }
      let data = ChartDataEntry(x: Double(index), y: data.average)
      
      dailyData.append(data)
    }
    
    return dailyData
  }
  
  private func configureAllTimeData(data: [PriceSummaryResponse]) -> (year: [ChartDataEntry], allTime: [ChartDataEntry]) {
    var yearData: [ChartDataEntry] = [], allTimeData: [ChartDataEntry] = []
    
    for (index, data) in data.enumerated() {
      let data = ChartDataEntry(x: Double(index), y: data.average)
      
      if (index < 365) {
        yearData.append(data)
      } else {
        allTimeData.append(data)
      }
    }
    
    return (year: yearData, allTime: allTimeData)
  }

  @objc private func refreshDisplayedPrice() {
    currencyValueManager?.latestExchangeRates(responseHandler: updateRatesRequest)
  }
}
