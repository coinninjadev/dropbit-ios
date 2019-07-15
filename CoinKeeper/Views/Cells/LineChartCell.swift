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

  var data: ChartData? {
    willSet {
      if newValue?.yMax != chart.data?.yMax || newValue?.xMax != chart.data?.xMax {
        chart.animate(xAxisDuration: 2, easingOption: .easeOutBack)
      }
    }
    didSet {
      highLabel.text = CKNumberFormatter.currencyFormatter.string(from: (data?.yMax ?? 0.0) as NSNumber)
      lowLabel.text = CKNumberFormatter.currencyFormatter.string(from: (data?.yMin ?? 0.0) as NSNumber)
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
