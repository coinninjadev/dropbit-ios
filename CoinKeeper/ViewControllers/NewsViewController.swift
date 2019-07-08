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
import SVProgressHUD

protocol NewsViewControllerDelegate: ViewControllerDismissable {
  func viewControllerDidRequestNewsData() -> Promise<NewsData>
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
  
  var monthlyDataSet: CandleChartData?
  var allTimeDataSet: CandleChartData?
  
  var dataToShow: CandleChartData?
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
    
    SVProgressHUD.show()
  
    //TODO: Grab news data
  }
  
  private func setupDataSet(_ priceSet: [HistoricPriceResponse]) -> [LineChartDataSet] {
    return [] //TODO
  }
  
  @objc private func refreshDisplayedPrice() {
    currencyValueManager?.latestExchangeRates(responseHandler: updateRatesRequest)
  }
}

