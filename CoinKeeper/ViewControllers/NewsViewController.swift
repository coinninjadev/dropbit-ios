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

protocol NewsViewControllerDelegate: CurrencyValueDataSourceType, ViewControllerDismissable, URLOpener {
  func viewControllerDidRequestNewsData(count: Int) -> Promise<[NewsArticleResponse]>
  func viewControllerDidRequestPriceDataFor(period: PricePeriod) -> Promise<[PriceSummaryResponse]>
  func viewControllerBecameVisible(_ viewController: UIViewController)
  func viewControllerWillShowNewsArticle(_ viewController: UIViewController)
}

final class NewsViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var tableView: UITableView!
  @IBOutlet var newsErrorLabel: UILabel!
  @IBOutlet var closeButton: UIButton!

  private var newsViewControllerDDS: NewsViewControllerDDS?

  lazy var updateRatesRequest: ExchangeRatesRequest = { [weak self] rates in
    let value = rates[.USD] as NSNumber?
    self?.newsViewControllerDDS?.newsData.currentPrice = value
    self?.tableView.reloadData()
  }

  static func newInstance(delegate: NewsViewControllerDelegate) -> NewsViewController {
    let vc = NewsViewController.makeFromStoryboard()
    vc.delegate = delegate
    vc.currencyValueManager = delegate
    return vc
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  private(set) weak var delegate: NewsViewControllerDelegate!
  private(set) weak var currencyValueManager: CurrencyValueDataSourceType?

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.registerNib(cellType: PriceCell.self)
    tableView.registerNib(cellType: TimePeriodCell.self)
    tableView.registerNib(cellType: NewsTitleCell.self)
    tableView.registerNib(cellType: LineChartCell.self)
    tableView.registerNib(cellType: NewsArticleCell.self)

    newsViewControllerDDS = NewsViewControllerDDS(delegate: self)

    tableView.delegate = newsViewControllerDDS
    tableView.dataSource = newsViewControllerDDS
    tableView.separatorStyle = .none
    tableView.showsVerticalScrollIndicator = false
    tableView.backgroundColor = .lightGrayBackground

    newsErrorLabel.font = .light(13)
    newsErrorLabel.textColor = .darkGrayText

    SVProgressHUD.show()

    CKNotificationCenter.subscribe(self, [.didUpdateExchangeRates: #selector(refreshDisplayedPrice)])
    currencyValueManager?.latestExchangeRates(responseHandler: updateRatesRequest)

    newsViewControllerDDS?.setupDataSet(coordinationDelegate: delegate)
  }

  @IBAction func closeButtonWasTouched() {
    SVProgressHUD.dismiss()
    delegate.viewControllerDidSelectClose(self)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    delegate.viewControllerBecameVisible(self)
  }

  @objc private func refreshDisplayedPrice() {
    currencyValueManager?.latestExchangeRates(responseHandler: updateRatesRequest)
  }
}

extension NewsViewController: NewsViewControllerDDSDelegate {

  func delegateRefreshNews() {
    tableView.reloadData()
  }

  func delegateDidRequestUrl(_ url: URL) {
    delegate.viewControllerWillShowNewsArticle(self)
    delegate.openURL(url, completionHandler: nil)
  }

  func delegateFinishedLoadingData() {
    SVProgressHUD.dismiss()
    tableView.isHidden = false
  }

  func delegateErrorLoadingData() {
    SVProgressHUD.dismiss()
    newsErrorLabel.isHidden = false
  }
}
