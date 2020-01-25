//
//  TodayViewController.swift
//  TodayExtension
//
//  Created by Mitchell Malleo on 1/17/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import NotificationCenter
import PromiseKit
import Charts

@objc(TodayViewController)

class TodayViewController: UIViewController, NCWidgetProviding {

  let todayView = TodayView()
  let coinNinjaProvider = CoinNinjaProvider()
  let newsNetworkManager: NewsNetworkManager
  let checkInNetworkManager: CheckInNetworkManager

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    newsNetworkManager = NewsNetworkManager(coinNinjaProvider: coinNinjaProvider)
    checkInNetworkManager = CheckInNetworkManager(coinNinjaProvider: coinNinjaProvider)
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    todayView.openAppButton.addTarget(self, action: #selector(openAppButtonWasTouched), for: .touchUpInside)
  }

  override func loadView() {
    view = todayView
  }

  func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
    let newsData = NewsData()

    checkInNetworkManager.checkIn()
      .then { (response: CheckInResponse) -> Promise<[PriceSummaryResponse]> in
        newsData.currentPrice = response.pricing.last as NSNumber?
        return self.newsNetworkManager.requestPriceData(period: .daily)
    }.done { dailyPrice in
      newsData.configureDailyData(data: dailyPrice.reversed())
      self.todayView.newsData = newsData
      completionHandler(NCUpdateResult.newData)
    }.catch { error in
      self.todayView.newsData = nil
      completionHandler(NCUpdateResult.failed)
    }
  }

  @objc private func openAppButtonWasTouched() {
    guard let url = DropBitUrlFactory.buildUrl(for: .widget) else { return }
    extensionContext?.open(url, completionHandler: nil)
  }

}
