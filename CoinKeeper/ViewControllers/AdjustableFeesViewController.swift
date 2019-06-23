//
//  AdjustableFeesViewController.swift
//  DropBit
//
//  Created by Ben Winters on 6/20/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

enum TransactionFeeMode: Int {
  case fast = 1 //UserDefaults returns 0 by default, 1 allows us to distinguish
  case slow
  case cheap

  static var defaultMode: TransactionFeeMode {
    return .fast
  }

  static func mode(for int: Int) -> TransactionFeeMode {
    return TransactionFeeMode(rawValue: int) ?? .defaultMode
  }

}

struct AdjustableFeesDataSource {
  var adjustableFeesEnabled: Bool
  var cellViewModels: [AdjustableFeesCellViewModel]

  func viewModel(for indexPath: IndexPath) -> AdjustableFeesCellViewModel? {
    return cellViewModels[safe: indexPath.row]
  }

  func selectedMode() -> TransactionFeeMode? {
    return cellViewModels.first(where: { $0.isSelected })?.mode
  }

  init(isEnabled: Bool, selectedMode: TransactionFeeMode) {
    self.adjustableFeesEnabled = isEnabled

    let orderedModes: [TransactionFeeMode] = [.fast, .slow, .cheap]
    self.cellViewModels = orderedModes.map { mode in
      return AdjustableFeesCellViewModel(isSelected: mode == selectedMode, mode: mode)
    }
  }

}

protocol AdjustableFeesViewControllerDelegate: ViewControllerURLDelegate {
  var adjustableFeesIsEnabled: Bool { get set }
  var preferredTransactionFeeMode: TransactionFeeMode { get set }
}

class AdjustableFeesViewController: BaseViewController, StoryboardInitializable {

  weak var delegate: AdjustableFeesViewControllerDelegate!

  static func newInstance(delegate: AdjustableFeesViewControllerDelegate) -> AdjustableFeesViewController {
    let vc = AdjustableFeesViewController.makeFromStoryboard()
    vc.dataSource = AdjustableFeesDataSource(isEnabled: delegate.adjustableFeesIsEnabled,
                                             selectedMode: delegate.preferredTransactionFeeMode)
    vc.delegate = delegate
    return vc
  }

  @IBOutlet var enableLabel: AdjustableFeesLabel!
  @IBOutlet var isEnabledSwitch: UISwitch!
  @IBOutlet var messageLabel: UILabel!
  @IBOutlet var tableView: UITableView!
  @IBOutlet var footnoteLabel: AdjustableFeesLabel!

  @IBAction func toggleAdjustableFeesEnabled(_ sender: UISwitch) {
    dataSource.adjustableFeesEnabled = sender.isOn
    refreshView()
  }

  @IBAction func performTooltip(_ sender: Any) {
    delegate.viewController(self, didRequestOpenURL: .adjustableFeesTooltip)
  }

  var dataSource: AdjustableFeesDataSource!

  override func viewDidLoad() {
    super.viewDidLoad()

    setLabelText()
    tableView.registerNib(cellType: AdjustableFeesTableViewCell.self)

    isEnabledSwitch.isOn = dataSource.adjustableFeesEnabled
    isEnabledSwitch.onTintColor = .primaryActionButton
    messageLabel.font = .regular(13)
    messageLabel.textColor = .darkGrayText

    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .clear
    tableView.isScrollEnabled = false
    tableView.reloadData()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    refreshView()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    if let selectedMode = dataSource.selectedMode() {
      delegate.preferredTransactionFeeMode = selectedMode
    }

    delegate.adjustableFeesIsEnabled = dataSource.adjustableFeesEnabled
  }

  /// Hide or show elements as appropriate
  private func refreshView() {
    let shouldHide = !dataSource.adjustableFeesEnabled

    UIView.animate(withDuration: 0.2) {
      self.tableView.isHidden = shouldHide
      self.messageLabel.isHidden = shouldHide
      self.footnoteLabel.isHidden = shouldHide
    }
  }

  private func setLabelText() {
    self.title = "ADJUSTABLE FEES"
    self.enableLabel.text = "Adjustable Fees"
    self.messageLabel.text = """
    Select the default fee you would like for your transactions.
    You will still be able to change the fee for each transaction on the send screen.
    """.removingMultilineLineBreaks()

    self.footnoteLabel.text = """
    *These time are estimates and may change based on the size of the mempool at the time of a transaction.
    """
  }

}

extension AdjustableFeesViewController: UITableViewDelegate {

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let vm = dataSource.viewModel(for: indexPath) else { return }
    let isEnabled = dataSource.adjustableFeesEnabled
    dataSource = AdjustableFeesDataSource(isEnabled: isEnabled, selectedMode: vm.mode)
    tableView.reloadData()
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 56
  }

}

extension AdjustableFeesViewController: UITableViewDataSource {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dataSource.cellViewModels.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let viewModel = dataSource.viewModel(for: indexPath) else { fatalError("fees cell data missing") }

    let cell = tableView.dequeue(AdjustableFeesTableViewCell.self, for: indexPath)
    cell.load(with: viewModel)
    return cell
  }

}
