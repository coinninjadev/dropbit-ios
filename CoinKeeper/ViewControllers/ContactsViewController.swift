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
  @IBOutlet var searchBar: UISearchBar!
  @IBOutlet var activityIndiciator: UIActivityIndicatorView!

  @IBAction func toggleDataSource(_ sender: UIButton) {
    if sender != button(forMode: self.mode) {
      setSelectedButton(to: sender)
    }
  }

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
    tableView.registerHeaderFooter(headerFooterType: ContactsTableViewHeader.self)
    tableView.tableFooterView = UIView()

    tableView.delegate = self
    tableView.dataSource = self

    do {
      try self.frc.performFetch()
    } catch {
      os_log("Contacts FRC failed to perform fetch: %@", log: logger, type: .error, error.localizedDescription)
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
    styleSearchBar()

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

  private func styleSearchBar() {
    guard let textField = searchBar.value(forKey: "_searchField") as? UITextField else {
      return
    }

    textField.borderStyle = .none
    textField.font = Theme.Font.searchPlaceholderLabel.font
    textField.backgroundColor = Theme.Color.lightGrayBackground.color
    let leadingOffset = UIOffset(horizontal: CGFloat(30), vertical: CGFloat(0))
    searchBar.setPositionAdjustment(leadingOffset, for: .search)
    textField.backgroundColor = Theme.Color.searchBarLightGray.color

    setupKeyboardDoneButton(for: [textField], action: #selector(doneButtonWasPressed))
    searchBar.searchTextPositionAdjustment = UIOffset(horizontal: 10.0, vertical: 0.0)
    searchBar.backgroundColor = Theme.Color.searchBarLightGray.color
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
    // To limit fetch frequency, call frc.performFetch() a moment after last key press.
    frc.fetchRequest.predicate = coordinationDelegate?.predicate(forSearch: searchText)

    let fetchSelector = #selector(performFetchForSearch)
    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: fetchSelector, object: nil)
    self.perform(fetchSelector, with: nil, afterDelay: 0.25)
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
    self.didSelectCachedNumber(at: indexPath)
  }

}

extension ContactsViewController: NSFetchedResultsControllerDelegate {

  // Not implementing animations because when the results update, it only uses tableView.move(...) which doesn't animate
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.reloadData()
  }

}

extension ContactsViewController: ContactCellDelegate {

  func didSelectCachedNumber(at indexPath: IndexPath) {
    guard let delegate = self.selectionDelegate else { return }

    let cachedNumber = frc.object(at: indexPath)
    trackEvent(forSelectedNumber: cachedNumber)

    coordinationDelegate?.viewControllerDidSelectPhoneNumber(self,
                                                             cachedNumber: cachedNumber,
                                                             validSelectionDelegate: delegate)
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
    didSelectCachedNumber(at: path)
  }

  func inviteButtonWasTouched(inCell cell: ContactCell) {
    guard let path = tableView.indexPath(for: cell) else { return }
    didSelectCachedNumber(at: path)
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
