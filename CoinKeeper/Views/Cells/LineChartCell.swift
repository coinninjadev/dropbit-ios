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

  var data: ChartData? {
    willSet {
      if newValue != data {
        chart.animate(xAxisDuration: 2, easingOption: .easeOutBack)
      }
    }
    didSet {
      chart.data = data
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    chart.backgroundColor = .lightGrayBackground
    chart.leftAxis.enabled = false
    chart.rightAxis.enabled = true
    chart.xAxis.enabled = false
    chart.pinchZoomEnabled = false
    chart.legend.form = .none
    chart.doubleTapToZoomEnabled = false

    isUserInteractionEnabled = false
    selectionStyle = .none
  }
}
