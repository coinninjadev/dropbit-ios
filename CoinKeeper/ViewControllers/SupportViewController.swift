//
//  SupportViewController.swift
//  DropBit
//
//  Created by BJ Miller on 5/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol SupportViewControllerDelegate: AnyObject {
  func viewControllerDidSelectClose(_ viewController: UIViewController)
  func viewController(_ viewController: UIViewController, didRequestOpenURL url: URL)
  func viewControllerSendDebuggingInfo(_ viewController: UIViewController)
}

final class SupportViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var sendDebugInfoButton: PrimaryActionButton!
  @IBOutlet var tableView: UITableView!
  @IBOutlet var titleLabel: SettingsTitleLabel!
  @IBOutlet var closeButton: UIButton!

  enum SupportType: CaseIterable {
    case faq, contactUs, termsOfUse, privacyPolicy

    var displayDescription: String {
      switch self {
      case .faq: return "FAQs"
      case .contactUs: return "Contact Us"
      case .termsOfUse: return "Terms of Use"
      case .privacyPolicy: return "Privacy Policy"
      }
    }

    var url: URL {
      switch self {
      case .faq: return CoinNinjaUrlFactory.buildUrl(for: .faqs)!
      case .contactUs: return CoinNinjaUrlFactory.buildUrl(for: .contactUs)!
      case .termsOfUse: return CoinNinjaUrlFactory.buildUrl(for: .termsOfUse)!
      case .privacyPolicy: return CoinNinjaUrlFactory.buildUrl(for: .privacyPolicy)!
      }
    }
  }

  static func newInstance(with delegate: SupportViewControllerDelegate) -> SupportViewController {
    let controller = SupportViewController.makeFromStoryboard()
    controller.generalCoordinationDelegate = delegate
    return controller
  }

  var coordinationDelegate: SupportViewControllerDelegate? {
    return generalCoordinationDelegate as? SupportViewControllerDelegate
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    sendDebugInfoButton.setTitle("SEND DEBUG INFO", for: .normal)
    tableView.delegate = self
    tableView.dataSource = self
    tableView.backgroundColor = .clear
    tableView.tableFooterView = UIView()
    tableView.registerNib(cellType: SettingCell.self)
    tableView.registerHeaderFooter(headerFooterType: SettingsTableViewSectionHeader.self)
  }

  @IBAction func close() {
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }

  @IBAction func sendDebugInfo() {
    coordinationDelegate?.viewControllerSendDebuggingInfo(self)
  }
}

extension SupportViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return SupportType.allCases.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeue(SettingCell.self, for: indexPath)
    let type = SupportType.allCases[indexPath.row]
    cell.titleLabel.text = type.displayDescription
    return cell
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 60.0
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 60.0
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let headerView = tableView.dequeueReusableHeaderFooterView(
      withIdentifier: SettingsTableViewSectionHeader.reuseIdentifier) as? SettingsTableViewSectionHeader else {
        return nil
    }
    let viewModel = SettingsHeaderFooterViewModel(title: "SUPPORT")
    headerView.load(with: viewModel)
    return headerView
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let type = SupportType.allCases[indexPath.row]
    coordinationDelegate?.viewController(self, didRequestOpenURL: type.url)
  }
}
