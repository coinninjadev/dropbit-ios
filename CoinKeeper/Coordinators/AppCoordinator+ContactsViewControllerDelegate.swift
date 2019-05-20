//
//  AppCoordinator+ContactsViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by Mitchell on 5/8/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import Moya
import enum Result.Result
import PromiseKit
import os.log
import CoreData

extension AppCoordinator: ContactsViewControllerDelegate {

  var contactCacheManager: ContactCacheManagerType {
    return persistenceManager.contactCacheManager
  }

  func viewControllerDidSelectPhoneNumber(_ viewController: UIViewController,
                                          cachedNumber: CCMPhoneNumber,
                                          validSelectionDelegate: SelectedValidContactDelegate) {
    var contactIsValid = true
    if let contact = ValidatedContact(cachedNumber: cachedNumber) {
      validSelectionDelegate.update(withSelectedContact: contact)
    } else {
      contactIsValid = false
    }

    viewController.dismiss(animated: true) {
      if !contactIsValid {
        let contactName = cachedNumber.cachedContact?.displayName
        self.showAlertForInvalidContactOrPhoneNumber(contactName: contactName, displayNumber: cachedNumber.displayNumber)
      }
    }
  }

  func showAlertForInvalidContactOrPhoneNumber(contactName: String?, displayNumber: String) {
    let nameText: String = contactName.map { name in "for \(name) " } ?? ""
    let message = """
    The phone number \(nameText)appears to be invalid (\(displayNumber)).

    Please use the Contacts app to enter the full mobile number, including country code, and try again.
    """

    let alert = self.alertManager.defaultAlert(withTitle: "Incomplete Number", description: message)
    self.navigationController.topViewController()?.present(alert, animated: true)
  }

  func showAlertForNoTwitterAuthorization() {
    let message = """
    In order to send bitcoin to a Twitter contact, you must authorize DropBit with your Twitter account.
    """

    let alert = self.alertManager.defaultAlert(withTitle: "No access to Twitter", description: message)
    self.navigationController.topViewController()?.present(alert, animated: true)
  }

  func viewControllerDidRequestRefreshVerificationStatuses(_ viewController: UIViewController, completion: @escaping ((Error?) -> Void)) {
    self.contactCacheDataWorker.refreshStatuses()
      .done { completion(nil) }
      .catch { error in
        completion(error)
        self.viewControllerDidEncounterError(viewController, error: error)
    }
  }

  func createFetchedResultsController() -> NSFetchedResultsController<CCMPhoneNumber> {
    return persistenceManager.contactCacheManager.createPhoneNumberFetchedResultsController()
  }

  func predicate(forSearch searchText: String) -> NSPredicate {
    return contactCacheManager.predicate(forSearch: searchText)
  }

  func viewControllerDidEncounterError(_ viewController: UIViewController, error: Error) {
    let title = "Error", detail = "Unable to connect to server. Please try again. \n\n\(error.localizedDescription)"
    let okConfig = AlertActionConfiguration(title: "Ok", style: .default) {
      viewController.dismiss(animated: true, completion: nil)
    }
    let alert = alertManager.alert(withTitle: title, description: detail, image: nil, style: .alert, actionConfigs: [okConfig])
    navigationController.topViewController()?.present(alert, animated: true)
  }

  func searchForTwitterUsers(with searchTerm: String) -> Promise<[TwitterUser]> {
    return networkManager.findTwitterUsers(using: searchTerm)
  }

  func defaultTwitterFriends() -> Promise<[TwitterUser]> {
    return networkManager.defaultFollowingList()
  }

  func viewController(_ viewController: UIViewController, didSelectTwitterUser user: TwitterUser) {

  }
}
