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
import os.log

protocol NewsViewControllerDelegate: ViewControllerDismissable, URLOpener {
  func viewControllerDidRequestNewsData(count: Int) -> Promise<[NewsArticleResponse]>
  func viewControllerDidRequestPriceDataFor(period: PricePeriod) -> Promise<[PriceSummaryResponse]>
}

class NewsViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var tableView: UITableView!
  @IBOutlet var loadingSpinner: UIActivityIndicatorView!

  private var newsViewControllerDDS: NewsViewControllerDDS?

  lazy var updateRatesRequest: ExchangeRatesRequest = { [weak self] rates in
    let value = rates[.USD] as NSNumber?
    self?.newsViewControllerDDS?.newsData.currentPrice = CKNumberFormatter.currencyFormatter.string(from: value ?? 0.0) ?? ""
    self?.tableView.reloadData()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  var coordinationDelegate: NewsViewControllerDelegate? {
    return generalCoordinationDelegate as? NewsViewControllerDelegate
  }

  override var generalCoordinationDelegate: AnyObject? {
    didSet {
      currencyValueManager = generalCoordinationDelegate as? CurrencyValueDataSourceType
    }
  }

  weak var currencyValueManager: CurrencyValueDataSourceType?

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.registerNib(cellType: PriceCell.self)
    tableView.registerNib(cellType: TimePeriodCell.self)
    tableView.registerNib(cellType: NewsTitleCell.self)
    tableView.registerNib(cellType: LineChartCell.self)
    tableView.registerNib(cellType: NewsArticleCell.self)

    newsViewControllerDDS = NewsViewControllerDDS()

    newsViewControllerDDS?.delegate = self
    tableView.delegate = newsViewControllerDDS
    tableView.dataSource = newsViewControllerDDS
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.backgroundColor = .lightGrayBackground

    CKNotificationCenter.subscribe(self, [.didUpdateExchangeRates: #selector(refreshDisplayedPrice)])
    currencyValueManager?.latestExchangeRates(responseHandler: updateRatesRequest)

    if let delegate = coordinationDelegate {
      newsViewControllerDDS?.setupDataSet(coordinationDelegate: delegate)
    }
  }

  @objc private func refreshDisplayedPrice() {
    currencyValueManager?.latestExchangeRates(responseHandler: updateRatesRequest)
  }
}

extension NewsViewController: NewsViewControllerDDSDelegate {

  func delegateDidRequestTableView() -> UITableView {
    return tableView
  }

  func delegateDidRequestUrl(_ url: URL) {
    coordinationDelegate?.openURL(url, completionHandler: nil)
  }

  func delegateFinishedLoadingData() {
    loadingSpinner.stopAnimating()
    tableView.isHidden = false
  }

  func delegateErrorLoadingData() {
    loadingSpinner.stopAnimating()
    //TODO
  }
}
