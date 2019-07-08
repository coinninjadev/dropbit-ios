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
  @IBOutlet var lineChartCell: CandleStickChartView!

  var data: ChartData? {
    willSet {
      if newValue != data {
        lineChartCell.animate(xAxisDuration: 2, easingOption: .easeOutBack)
      }
    }
    didSet {
      lineChartCell.data = data
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    lineChartCell.backgroundColor = .lightGrayBackground
    lineChartCell.leftAxis.enabled = false
    lineChartCell.rightAxis.enabled = false
    lineChartCell.xAxis.enabled = false
    lineChartCell.pinchZoomEnabled = false
    lineChartCell.legend.form = .none
    lineChartCell.doubleTapToZoomEnabled = false

    isUserInteractionEnabled = false
    selectionStyle = .none
  }
}
