//
//  ContactsViewController.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/3/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import CoreData
import PromiseKit
import os.log

protocol ContactsViewControllerDelegate: ViewControllerDismissable, URLOpener {

  var analyticsManager: AnalyticsManagerType { get }

  func createFetchedResultsController() -> NSFetchedResultsController<CCMPhoneNumber>

  func predicate(forSearch searchText: String) -> NSPredicate

  /// The delegate should show a hud and disable interactions, check the API for any changes in the verification
  /// status of all cached numbers, and persist the changes such that the `frc` is updated automatically.
  func viewControllerDidRequestRefreshVerificationStatuses(_ viewController: UIViewController, completion: @escaping ((Error?) -> Void))

  /// The delegate should evaluate whether the phone number is a valid recipient and if valid,
  /// call update() on the `validSelectionDelegate`.
  func viewControllerDidSelectPhoneNumber(_ viewController: UIViewController,
                                          cachedNumber: CCMPhoneNumber,
                                          validSelectionDelegate: SelectedValidContactDelegate)

  func showAlertForInvalidContactOrPhoneNumber(contactName: String?, displayNumber: String)
  func searchForTwitterUsers(with searchTerm: String) -> Promise<[TwitterUser]>
}

protocol SelectedValidContactDelegate: AnyObject {
  func update(withSelectedContact contact: ContactType)
}

enum ContactsViewControllerMode {
  case contacts
  case twitter
}

class ContactsViewController: PresentableViewController, StoryboardInitializable {

  @IBOutlet var tableView: UITableView!
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var modeContainerView: UIView!
  @IBOutlet var contactsButton: UIButton!
  @IBOutlet var twitterButton: UIButton!
  @IBOutlet var selectedButtonIndicator: UIView!
  @IBOutlet var indicatorLeadingConstraint: NSLayoutConstraint!
  @IBOutlet var searchBar: CNContactSearchBar!
  @IBOutlet var activityIndiciator: UIActivityIndicatorView!

  @IBAction func toggleDataSource(_ sender: UIButton) {
    if sender != button(forMode: self.mode) {
      setSelectedButton(to: sender)
    }
  }

  private lazy var twitterUserDataSource: TwitterSearchDataSource = {
    return TwitterSearchDataSource(tableView: self.tableView)
  }()

  private func button(forMode mode: ContactsViewControllerMode) -> UIButton {
    switch mode {
    case .contacts: return contactsButton
    case .twitter:  return twitterButton
    }
  }

  private func setSelectedButton(to button: UIButton, animated: Bool = true) {
    if button == contactsButton {
      mode = .contacts
    } else if button == twitterButton {
      mode = .twitter
    }

    setupTableView()

    let duration: TimeInterval = animated ? 0.3 : 0
    UIView.animate(withDuration: duration) {
      self.indicatorLeadingConstraint.constant = self.indicatorOffset(for: button)
      self.modeContainerView.layoutIfNeeded()
    }
  }

  private func indicatorOffset(for button: UIButton) -> CGFloat {
    let indicatorWidth = selectedButtonIndicator.frame.width
    let buttonWidth = button.frame.width
    let buttonXPosition = button.frame.minX
    let centeringOffset = (buttonWidth - indicatorWidth)/2
    let fullOffset = buttonXPosition + centeringOffset
    return fullOffset
  }

  private let logger = OSLog(subsystem: "com.coinninja.coinkeeper.contactsviewcontroller", category: "contacts_view_controller")

  var mode: ContactsViewControllerMode = .contacts

  static func newInstance(mode: ContactsViewControllerMode,
                          coordinationDelegate: ContactsViewControllerDelegate,
                          selectionDelegate: SelectedValidContactDelegate) -> ContactsViewController {
    let vc = ContactsViewController.makeFromStoryboard()
    vc.mode = mode
    vc.generalCoordinationDelegate = coordinationDelegate
    vc.selectionDelegate = selectionDelegate
    vc.modalPresentationStyle = .overFullScreen
    return vc
  }

  var coordinationDelegate: ContactsViewControllerDelegate? {
    return generalCoordinationDelegate as? ContactsViewControllerDelegate
  }

  weak var selectionDelegate: SelectedValidContactDelegate?

  var frc: NSFetchedResultsController<CCMPhoneNumber>!

  func setupTableView() {
    guard let delegate = coordinationDelegate else { return }
    self.frc = delegate.createFetchedResultsController()
    self.frc.delegate = self

    tableView.backgroundColor = Theme.Color.lightGrayBackground.color
    view.backgroundColor = Theme.Color.lightGrayBackground.color

    tableView.registerNib(cellType: ContactCell.self)
    tableView.registerNib(cellType: TwitterUserTableViewCell.self)
    tableView.registerHeaderFooter(headerFooterType: ContactsTableViewHeader.self)
    tableView.tableFooterView = UIView()

    tableView.delegate = self
    switch mode {
    case .contacts:
      tableView.dataSource = self
      do {
        try self.frc.performFetch()
        tableView.reloadData()
      } catch {
        os_log("Contacts FRC failed to perform fetch: %@", log: logger, type: .error, error.localizedDescription)
      }
    case .twitter:
      tableView.dataSource = self.twitterUserDataSource
      tableView.reloadData()
    }

  }

  private func setupModeSelector() {
    let textColor = Theme.Color.darkBlueText.color
    let font = Theme.Font.compactButtonTitle.font
    let contactsTitle = NSAttributedString(imageName: "contactsIcon",
                                           imageSize: CGSize(width: 9, height: 14),
                                           title: "CONTACTS",
                                           sharedColor: textColor,
                                           font: font)
    contactsButton.setAttributedTitle(contactsTitle, for: .normal)

    let twitterTitle = NSAttributedString(imageName: "twitterBird",
                                          imageSize: CGSize(width: 14, height: 12),
                                          title: "TWITTER",
                                          sharedColor: textColor,
                                          font: font)
    twitterButton.setAttributedTitle(twitterTitle, for: .normal)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupModeSelector()
    setupTableView()
    setupSearchBar()

    activityIndiciator.hidesWhenStopped = true
    searchBar.delegate = self

    let buttonToSelect = self.button(forMode: mode)
    setSelectedButton(to: buttonToSelect, animated: false)

    refreshContactVerificationStatuses()
  }

  private func refreshContactVerificationStatuses() {
    guard let delegate = coordinationDelegate else { return }
    activityIndiciator.startAnimating()
    delegate.viewControllerDidRequestRefreshVerificationStatuses(self) { [weak self] error in
      if let err = error, let self = self {
        os_log("Failed to request users: %{private}@", log: self.logger, type: .error, err.localizedDescription)
      }

      self?.activityIndiciator.stopAnimating()
    }
  }

  private func setupSearchBar() {
    guard let textField = searchBar.searchTextField else { return }
    setupKeyboardDoneButton(for: [textField], action: #selector(doneButtonWasPressed))
  }

  @objc func doneButtonWasPressed() {
    searchBar.resignFirstResponder()
  }

  @IBAction func closeButtonWasTouched() {
    searchBar.resignFirstResponder()
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }

}

extension ContactsViewController: UISearchBarDelegate {

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    switch mode {
    case .contacts:
      // To limit fetch frequency, call frc.performFetch() a moment after last key press.
      frc.fetchRequest.predicate = coordinationDelegate?.predicate(forSearch: searchText)

      let fetchSelector = #selector(performFetchForSearch)
      NSObject.cancelPreviousPerformRequests(withTarget: self, selector: fetchSelector, object: nil)
      self.perform(fetchSelector, with: nil, afterDelay: 0.25)
    case .twitter:
      guard searchText.count > 2 else {
        twitterUserDataSource.update(users: [])
        return
      }
      _ = coordinationDelegate?.searchForTwitterUsers(with: searchText)
        .done { self.twitterUserDataSource.update(users: $0) }
    }
  }

  @objc func performFetchForSearch() {
    do {
      try frc.performFetch()
      tableView.reloadData()
    } catch {
      print(error.localizedDescription)
    }
  }

}

extension ContactsViewController: UITableViewDelegate, UITableViewDataSource {

  func numberOfSections(in tableView: UITableView) -> Int {
    return frc.sections?.count ?? 0
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return frc.sections?[section].numberOfObjects ?? 0
  }

  private func shouldShowHeader(forSection section: Int) -> Bool {
    if let sectionCount = frc.sections?.count, section == sectionCount - 1 { // is last section
      return true
    } else {
      return false
    }
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return shouldShowHeader(forSection: section) ? 39.0 : 0
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

    if shouldShowHeader(forSection: section) {
      let headerView = tableView.dequeueReusableHeaderFooterView(
        withIdentifier: ContactsTableViewHeader.reuseIdentifier) as? ContactsTableViewHeader
      headerView?.delegate = self
      return headerView

    } else {
      return nil
    }
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 71.0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cachedNumber = frc.object(at: indexPath)
    let cell = tableView.dequeue(ContactCell.self, for: indexPath)

    cell.delegate = self
    cell.load(with: cachedNumber)

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.didSelectContact(at: indexPath)
  }

}

extension ContactsViewController: NSFetchedResultsControllerDelegate {

  // Not implementing animations because when the results update, it only uses tableView.move(...) which doesn't animate
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.reloadData()
  }

}

extension ContactsViewController: ContactCellDelegate {

  func didSelectContact(at indexPath: IndexPath) {
    switch mode {
    case .contacts:
      guard let delegate = self.selectionDelegate else { return }

      let cachedNumber = frc.object(at: indexPath)
      trackEvent(forSelectedNumber: cachedNumber)

      coordinationDelegate?.viewControllerDidSelectPhoneNumber(self,
                                                               cachedNumber: cachedNumber,
                                                               validSelectionDelegate: delegate)
    case .twitter:
      break // hit API with snowflake to find user
    }
  }

  private func trackEvent(forSelectedNumber number: CCMPhoneNumber) {
    switch number.verificationStatus {
    case .notVerified:
      coordinationDelegate?.analyticsManager.track(event: .dropbitContactPressed, with: nil)
    case .verified:
      coordinationDelegate?.analyticsManager.track(event: .coinKeeperContactPressed, with: nil)
    }
  }

  func sendButtonWasTouched(inCell cell: ContactCell) {
    guard let path = tableView.indexPath(for: cell) else { return }
    didSelectContact(at: path)
  }

  func inviteButtonWasTouched(inCell cell: ContactCell) {
    guard let path = tableView.indexPath(for: cell) else { return }
    didSelectContact(at: path)
  }

}

extension ContactsViewController: ContactsTableViewHeaderDelegate {

  func whatIsButtonWasTouched() {
    guard let delegate = coordinationDelegate,
      let url = CoinNinjaUrlFactory.buildUrl(for: .bitcoinSMS)
      else { return }
    delegate.analyticsManager.track(event: .whatIsDropbitPressed, with: nil)
    delegate.openURL(url, completionHandler: nil)
  }

}
