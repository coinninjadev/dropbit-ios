//
//  NewsData.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/10/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Charts

struct NewsData {
  var articles: [NewsArticleResponse] = []

  var dayPriceResponse: [PriceSummaryResponse] = []
  var dayPriceData: LineChartDataSet = LineChartDataSet()

  var allTimePriceResponse: [PriceSummaryResponse] = []
  var allTimePriceData: LineChartDataSet = LineChartDataSet()

  var yearlyPriceResponse: [PriceSummaryResponse] = []
  var yearlyPriceData: LineChartDataSet = LineChartDataSet()

  var monthlyPriceResponse: [PriceSummaryResponse] = []
  var monthlyPriceData: LineChartDataSet = LineChartDataSet()

  var weeklyPriceResponse: [PriceSummaryResponse] = []
  var weeklyPriceData: LineChartDataSet = LineChartDataSet()

  var currentPrice: NSNumber?

  var displayPrice: String {
    return CKNumberFormatter.usdCurrencyFormatter.string(from: self.currentPrice ?? 0.0) ?? ""
  }

  func getDataSetForTimePeriod(_ timePeriod: TimePeriodCell.Period) -> LineChartDataSet {
    switch timePeriod {
    case .daily:
      return dayPriceData
    case .week:
      return weeklyPriceData
    case .monthly:
      return monthlyPriceData
    case .yearly:
      return yearlyPriceData
    case .alltime:
      return allTimePriceData
    }
  }

  func getPriceMovement(_ timePeriod: TimePeriodCell.Period) -> (gross: Double, percentage: Double) {
    let priceResponse: [PriceSummaryResponse]

    switch timePeriod {
    case .week:
      priceResponse = weeklyPriceResponse
    case .monthly:
      priceResponse = monthlyPriceResponse
    case .yearly:
      priceResponse = yearlyPriceResponse
    case .alltime:
      priceResponse = allTimePriceResponse
    default:
      priceResponse = dayPriceResponse
    }

    let gross = (priceResponse.last?.average ?? 0.0) - (priceResponse.first?.average ?? 0.0)
    let percentage = gross / (currentPrice as? Double ?? 1.0) * 100

    return (gross: gross, percentage: percentage)
  }
}
