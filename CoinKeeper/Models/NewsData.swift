//
//  NewsData.swift
//  DropBit
//
//  Created by Mitchell Malleo on 7/10/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Charts

enum TimePeriod {
  case daily
  case week
  case monthly
  case yearly
  case alltime
}

struct WeekMonthChartData {
  let weekData: [ChartDataEntry]
  let weekResponse: [PriceSummaryResponse]
  let monthData: [ChartDataEntry]
  let monthResponse: [PriceSummaryResponse]
}

struct AllTimePriceChartData {
  let year: [ChartDataEntry]
  let yearResponse: [PriceSummaryResponse]
  let allTime: [ChartDataEntry]
  let allTimeResponse: [PriceSummaryResponse]
}

class NewsData {

  /*
   Monthly endpoint of price is broken down by hours
   Average of 30 days times 24 hours = 720
   720 hours minus a weeks worth of hours (7 x 24 = 168) is 552
  */
  private var weekDataSourceOffset: Int {
    let hoursInWeek = 168
    return monthlyDataSourceOffset - hoursInWeek
  }

  private var monthlyDataSourceOffset: Int {
    let daysInMonth = 30, hoursInWeek = 24
    return daysInMonth * hoursInWeek
  }

  private var dailyDataSourceOffset: Int {
    let minutesInHour = 60, hoursInDay = 24
    return minutesInHour * hoursInDay
  }

  private var yearDataSourceOffset: Int {
    return 365
  }

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
    return FiatFormatter(currency: .USD, withSymbol: true).string(fromNumber: self.currentPrice ?? 0.0) ?? ""
  }

  func getDataSetForTimePeriod(_ timePeriod: TimePeriod) -> LineChartDataSet {
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

  func getPriceMovement(_ timePeriod: TimePeriod) -> (gross: Double, percentage: Double) {
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

  func configureWeekAndMonthData(data: [PriceSummaryResponse]) {
    let monthStartIndex = max(0, data.count - monthlyDataSourceOffset), monthResponse = Array(data[monthStartIndex..<data.count])
    let weekStartIndex = max(0, monthResponse.count - weekDataSourceOffset)
    let weekResponseStartIndex = max(0, monthResponse.count - weekStartIndex)
    let weekResponse = Array(monthResponse[weekResponseStartIndex..<monthResponse.count])
    let weekData = weekResponse.enumerated().map { index, element in return ChartDataEntry(x: Double(index), y: element.average) }
    let monthData = monthResponse.enumerated().map { index, element in return ChartDataEntry(x: Double(index), y: element.average) }
    let monthlyData = WeekMonthChartData(weekData: weekData, weekResponse: weekResponse, monthData: monthData, monthResponse: monthResponse)

    weeklyPriceData = LineChartDataSet(entries: monthlyData.weekData, label: nil)
    weeklyPriceResponse = monthlyData.weekResponse
    monthlyPriceData = LineChartDataSet(entries: monthlyData.monthData, label: nil)
    monthlyPriceResponse = monthlyData.monthResponse
  }

  func configureDailyData(data: [PriceSummaryResponse]) {
    let startIndex = max(0, data.count - dailyDataSourceOffset)
    let responseData = Array(data[startIndex..<data.count]).enumerated().compactMap { $0 % 5 == 0 ? $1 : nil }
    let dailyData = responseData.enumerated().map { index, element in return ChartDataEntry(x: Double(index), y: element.average) }

    dayPriceData = LineChartDataSet(entries: dailyData, label: nil)
    dayPriceResponse = responseData
  }

  func configureYearAndAllTimeData(data: [PriceSummaryResponse]) {
    let yearStartIndex = max(0, data.count - yearDataSourceOffset), yearResponse = Array(data[yearStartIndex..<data.count])
    let yearData = yearResponse.enumerated().map { index, element in return ChartDataEntry(x: Double(index), y: element.average) }
    let allTimeResponseData = Array(data[0..<data.count]).enumerated().compactMap { $0 % 5 == 0 ? $1 : nil }
    let data = allTimeResponseData.enumerated().map { index, element in return ChartDataEntry(x: Double(index), y: element.average) }

    let allTimeData = AllTimePriceChartData(year: yearData, yearResponse: yearResponse, allTime: data, allTimeResponse: allTimeResponseData)

    allTimePriceData = LineChartDataSet(entries: allTimeData.allTime, label: nil)
    allTimePriceResponse = allTimeData.allTimeResponse
    yearlyPriceData = LineChartDataSet(entries: allTimeData.year, label: nil)
    yearlyPriceResponse = allTimeData.yearResponse
  }
}
