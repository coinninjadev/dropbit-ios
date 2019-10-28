//
//  AppCoordinator+GetBitcoinViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 4/15/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

extension AppCoordinator: GetBitcoinViewControllerDelegate {

  func viewControllerFindBitcoinATMNearMe(_ viewController: GetBitcoinViewController) {
    analyticsManager.track(event: .buyBitcoinAtATM, with: nil)
    permissionManager.requestPermission(for: .location) { (status) in
      switch status {
      case .authorized, .notDetermined:
        guard let coordinate = self.locationManager.location?.coordinate,
          let url = CoinNinjaUrlFactory.buildUrl(for: .buyAtATM(coordinate)) else {
            self.locationManager.requestLocation() //Attempt to repair for next location request
            return
        }
        self.openURL(url, completionHandler: nil)
      case .denied, .disabled:
        let description = "To use the location-based services of finding Bitcoin ATMs near you," +
        " please enable location services in the iOS Settings app."
        let controller = self.alertManager.defaultAlert(withTitle: "Location Services not enabled", description: description)
        self.navigationController.topViewController()?.present(controller, animated: true, completion: nil)
      }
    }
  }

  func viewControllerBuyWithApplePay(_ viewController: GetBitcoinViewController, address: String) {
    analyticsManager.track(event: .buyWithQuickPay, with: nil)
    guard address.asNilIfEmpty() != nil else {
      let warning = "An error occurred: No Bitcoin receive address was detected. Please try again later."
      self.alertManager.showError(message: warning, forDuration: 2.0)
      return
    }
    viewControllerRequestedAuthenticationSuspension(viewController)
    guard let url = CoinNinjaUrlFactory.buildUrl(for: .buyWithApplePay(address)) else { return }
    openURLExternally(url, completionHandler: nil)
  }

  private func copyNextAddressAndPresentVC(destinationURL: URL) {
    guard let addressSource = self.walletManager?.createAddressDataSource() else { return }
    let context = persistenceManager.viewContext
    let nextAddress = addressSource.nextAvailableReceiveAddress(forServerPool: false,
                                                                indicesToSkip: [],
                                                                in: context)?.address

    if let address = nextAddress, let topVC = self.navigationController.topViewController() {
      UIPasteboard.general.string = address
      let copiedAddressVC = GetBitcoinCopiedAddressViewController.newInstance(address: address,
                                                                              destinationURL: destinationURL,
                                                                              delegate: self)
      topVC.present(copiedAddressVC, animated: true, completion: nil)
    }
  }
}

extension AppCoordinator: GetBitcoinCopiedAddressViewControllerDelegate {
  func viewControllerDidCopyAddress(_ viewController: UIViewController) {
    self.alertManager.showSuccessHUD(withStatus: "Address copied to clipboard!", duration: 2.0, completion: nil)
  }
}
