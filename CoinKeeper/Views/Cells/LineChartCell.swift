//
//  LineChartCell.swift
//  DropBit
//
//  Created by Mitchell Malleo on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import Charts

class LineChartCell: UITableViewCell {
  @IBOutlet var chart: LineChartView!
  @IBOutlet var highLabel: UILabel!
  @IBOutlet var lowLabel: UILabel!

  private var shouldAnimate = false

  var data: ChartData? {
    willSet {
      if newValue?.yMax != chart.data?.yMax || newValue?.xMax != chart.data?.xMax {
        if shouldAnimate {
          chart.animate(xAxisDuration: 2, easingOption: .easeOutBack)
        } else {
          chart.data = data
          shouldAnimate = true
        }
      }
    }
    didSet {
      let maxNumber = NSNumber(value: data?.yMax ?? 0.0)
      let minNumber = NSNumber(value: data?.yMin ?? 0.0)
      let formatter = FiatFormatter(currency: .USD, withSymbol: true)
      highLabel.text = formatter.string(fromNumber: maxNumber)
      lowLabel.text = formatter.string(fromNumber: minNumber)
      chart.data = data
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    chart.backgroundColor = .lightGrayBackground
    highLabel.backgroundColor = .lightGrayBackground
    lowLabel.backgroundColor = .lightGrayBackground
    backgroundColor = .lightGrayBackground
    chart.leftAxis.enabled = false
    chart.rightAxis.enabled = false
    chart.xAxis.enabled = false
    chart.pinchZoomEnabled = false
    chart.legend.form = .none
    chart.doubleTapToZoomEnabled = false

    isUserInteractionEnabled = false
    selectionStyle = .none

    highLabel.font = .regular(11)
    highLabel.textColor = .black
    lowLabel.font = .regular(11)
    lowLabel.textColor = .black
  }
}
