//
//  EarnPageViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 12/2/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol EarnViewControllerDelegate: ViewControllerDismissable, CopyToClipboardMessageDisplayable {
  func viewControllerDidPressShareButton(_ viewController: UIViewController)
  func viewControllerRestrictionsButtonWasTouched(_ viewController: UIViewController)
  func viewControllerDidSelectVerify(_ viewController: UIViewController)
}

class EarnViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var tableView: UITableView!

  weak var delegate: EarnViewControllerDelegate!
  private var referralLink: String?

  static func newInstance(delegate: EarnViewControllerDelegate,
                          referralLink: String?) -> EarnViewController {
    let viewController = EarnViewController.makeFromStoryboard()
    viewController.delegate = delegate
    viewController.referralLink = referralLink
    return viewController
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    var elements: [AccessibleViewElement] = [(self.view, .earn(.page))]
    if let button = (tableView.cellForRow(at: IndexPath(item: 0, section: 0)) as? EarnTableViewCell)?.closeButton {
      elements.append((button, .earn(.closeButton)))
    }
    return elements
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.registerNib(cellType: EarnTableViewCell.self)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.showsVerticalScrollIndicator = false
  }

}

extension EarnViewController: EarnTableViewCellDelegate {

  func restrictionsButtonWasTouched() {
    delegate?.viewControllerRestrictionsButtonWasTouched(self)
  }

  func referralLabelWasTouched() {
    guard let referralLink = referralLink else { return }
    UIPasteboard.general.string = referralLink
    delegate?.viewControllerSuccessfullyCopiedToClipboard(message: "Referral added to clipboard", viewController: self)
  }

  func trackReferralButtonWasTouched() {
    guard referralLink != nil else { return }
    delegate?.viewControllerDidPressShareButton(self)
  }

  func verificationButtonWasTouched() {
    delegate?.viewControllerDidSelectVerify(self)
  }

  func closeButtonWasTouched() {
    delegate?.viewControllerDidSelectClose(self)
  }
}

extension EarnViewController: UITableViewDelegate, UITableViewDataSource {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UIScreen.main.relativeSize != .tall ? 700 : UIScreen.main.bounds.size.height
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeue(EarnTableViewCell.self, for: indexPath)
    cell.delegate = self
    cell.referralLink = referralLink
    return cell
  }

}
