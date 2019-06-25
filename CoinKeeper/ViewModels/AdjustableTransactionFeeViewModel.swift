//
//  AdjustableTransactionFeeViewModel.swift
//  DropBit
//
//  Created by Ben Winters on 6/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import CNBitcoinKit

struct AdjustableTransactionFeeViewModel {

  var selectedFeeType: TransactionFeeType
  let lowFeeTxData: CNBTransactionData //must not be nil
  let mediumFeeTxData: CNBTransactionData?
  let highFeeTxData: CNBTransactionData?

  init(selectedFeeType: TransactionFeeType,
       lowFeeTxData: CNBTransactionData,
       mediumFeeTxData: CNBTransactionData?,
       highFeeTxData: CNBTransactionData?) {
    self.selectedFeeType = selectedFeeType
    self.lowFeeTxData = lowFeeTxData
    self.mediumFeeTxData = mediumFeeTxData
    self.highFeeTxData = highFeeTxData
  }

  private let sortedFeeTypes: [TransactionFeeType] = [.fast, .slow, .cheap]

  var selectedTypeIndex: Int {
    return sortedFeeTypes.firstIndex(of: selectedFeeType) ?? 0
  }

  var segmentModels: [AdjustableFeesSegmentViewModel] {
    return sortedFeeTypes.map { feeType in
      return AdjustableFeesSegmentViewModel(title: self.title(for: feeType),
                                            isSelected: feeType == self.selectedFeeType,
                                            isEnabled: self.transactionData(for: feeType) != nil)
    }
  }

  var applicableTransactionData: CNBTransactionData {
    return transactionData(for: selectedFeeType) ?? lowFeeTxData
  }

  private func transactionData(for mode: TransactionFeeType) -> CNBTransactionData? {
    switch mode {
    case .fast:   return highFeeTxData
    case .slow:   return mediumFeeTxData
    case .cheap:  return lowFeeTxData
    }
  }

  private func title(for mode: TransactionFeeType) -> String {
    switch mode {
    case .fast:   return "FAST"
    case .slow:   return "SLOW"
    case .cheap:  return "CHEAP"
    }
  }

  private func waitTimeDescription(for type: TransactionFeeType) -> String {
    switch type {
    case .fast:   return "10 minutes"
    case .slow:   return "20-60 minutes"
    case .cheap:  return "24 hours+"
    }
  }

  var attributedWaitTimeDescription: NSAttributedString {
    let attrString = NSMutableAttributedString.light("Approximate wait time: ",
                                                     size: 11,
                                                     color: .darkBlueText)
    let desc = waitTimeDescription(for: selectedFeeType)
    attrString.appendSemiBold(desc, size: 11)
    return attrString
  }

}

struct AdjustableFeesSegmentViewModel {
  let title: String
  let isSelected: Bool
  let isEnabled: Bool
}
