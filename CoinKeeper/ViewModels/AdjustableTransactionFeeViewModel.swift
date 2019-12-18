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
  let isAdjustable: Bool

  init(preferredFeeType: TransactionFeeType,
       lowFeeTxData: CNBTransactionData,
       mediumFeeTxData: CNBTransactionData?,
       highFeeTxData: CNBTransactionData?,
       isAdjustable: Bool) {
    self.selectedFeeType = preferredFeeType
    self.lowFeeTxData = lowFeeTxData
    self.mediumFeeTxData = mediumFeeTxData
    self.highFeeTxData = highFeeTxData
    self.isAdjustable = isAdjustable

    if transactionData(for: preferredFeeType) == nil {
      selectedFeeType = .cheap
    }
  }

  func copy(selecting selectedType: TransactionFeeType) -> AdjustableTransactionFeeViewModel {
    return AdjustableTransactionFeeViewModel(preferredFeeType: selectedType,
                                             lowFeeTxData: self.lowFeeTxData,
                                             mediumFeeTxData: self.mediumFeeTxData,
                                             highFeeTxData: self.highFeeTxData,
                                             isAdjustable: self.isAdjustable)
  }

  private let sortedFeeTypes: [TransactionFeeType] = [.fast, .slow, .cheap]

  var selectedTypeIndex: Int {
    return sortedFeeTypes.firstIndex(of: selectedFeeType) ?? 0
  }

  var segmentModels: [AdjustableFeesSegmentViewModel] {
    return sortedFeeTypes.map { feeType in
      return AdjustableFeesSegmentViewModel(type: feeType,
                                            title: self.title(for: feeType),
                                            isSelected: feeType == self.selectedFeeType,
                                            isSelectable: self.transactionData(for: feeType) != nil)
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
  let type: TransactionFeeType
  let title: String
  let isSelected: Bool
  let isSelectable: Bool
}
