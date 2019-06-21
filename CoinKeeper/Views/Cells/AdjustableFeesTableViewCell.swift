//
//  AdjustableFeesTableViewCell.swift
//  DropBit
//
//  Created by Ben Winters on 6/21/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

struct AdjustableFeesCellViewModel {
  let isSelected: Bool
  let mode: TransactionFeeMode
  var description: String {
    switch mode {
    case .fast:   return "Fast: Approximately 10 minutes"
    case .slow:   return "Slow: Approximately 20-60 minutes"
    case .cheap:  return "Cheap: Approximately 24 hours+"
    }
  }
}

class AdjustableFeesTableViewCell: UITableViewCell {

  @IBOutlet var titleLabel: AdjustableFeesLabel!
  @IBOutlet var separatorView: UIView!
  @IBOutlet var checkmarkImage: UIImageView!

  func load(with viewModel: AdjustableFeesCellViewModel) {
    titleLabel.text = viewModel.description
    checkmarkImage.isHidden = !viewModel.isSelected
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    selectionStyle = .none
    backgroundColor = .clear
    separatorView.backgroundColor = .graySeparator
  }

}
