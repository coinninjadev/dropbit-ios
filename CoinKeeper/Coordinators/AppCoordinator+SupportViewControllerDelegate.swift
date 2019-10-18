//
//  AppCoordinator+SupportViewControllerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 5/29/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import MessageUI

extension AppCoordinator: SupportViewControllerDelegate {
  func viewControllerSendDebuggingInfo(_ viewController: UIViewController) {
    // show confirmation first
    let message = "The debug report will not include any data allowing us access to your Bitcoin. However, " +
    "it may contain personal information, such as phone numbers and memos.\n"
    let cancelAction = AlertActionConfiguration(title: "Cancel", style: .cancel, action: nil)
    let okAction = AlertActionConfiguration(title: "OK", style: .default) { [weak self] in
      self?.presentDebugInfo(from: viewController)
    }
    let actions: [AlertActionConfigurationType] = [cancelAction, okAction]
    let alertViewModel = AlertControllerViewModel(title: message, description: nil, image: nil, style: .alert, actions: actions)
    let alertController = alertManager.alert(from: alertViewModel)
    viewController.present(alertController, animated: true, completion: nil)
  }

  private func presentDebugInfo(from viewController: UIViewController) {
    guard let dbFileURL = self.persistenceManager.persistentStore()?.url else {
      self.alertManager.hideActivityHUD(withDelay: 0) {
        self.alertManager.showError(message: "Failed to find database", forDuration: 4.0)
      }
      return
    }
    let shmFileURL = URL(string: dbFileURL.absoluteString + "-shm")
    let walFileURL = URL(string: dbFileURL.absoluteString + "-wal")
    guard MFMailComposeViewController.canSendMail() else {
      self.alertManager.hideActivityHUD(withDelay: 0) {
        self.alertManager.showError(message: "Your mail client is not configured", forDuration: 4.0)
      }
      return
    }

    let mailVC = MFMailComposeViewController()
    mailVC.setToRecipients(["support@coinninja.com"])
    mailVC.setSubject("Debug info")
    let iosVersion = UIDevice.current.systemVersion
    let versionKey: String = "CFBundleShortVersionString"
    let dropBitVersion = "\(Bundle.main.infoDictionary?[versionKey] ?? "Unknown")"
    let body =
    """
    This debugging info is shared with the engineers to diagnose potential issues.

    Describe here what issues you are experiencing:



    ----------------------------------
    iOS version: \(iosVersion)
    DropBit version: \(dropBitVersion)
    """
    mailVC.setMessageBody(body, isHTML: false)

    if let dbData = try? Data(contentsOf: dbFileURL) {
      mailVC.addAttachmentData(dbData, mimeType: "application/vnd.sqlite3", fileName: "CoinNinjaDB.sqlite")
    }
    if let walURL = walFileURL, let walData = try? Data(contentsOf: walURL) {
      mailVC.addAttachmentData(walData, mimeType: "application/vnd.sqlite3", fileName: "CoinNinjaDB.sqlite-wal")
    }
    if let shmURL = shmFileURL, let shmData = try? Data(contentsOf: shmURL) {
      mailVC.addAttachmentData(shmData, mimeType: "application/vnd.sqlite3", fileName: "CoinNinjaDB.sqlite-shm")
    }

    if let logData = log.fileData() {
      mailVC.addAttachmentData(logData, mimeType: "text/txt", fileName: CKLogFileWriter.fileName)
    }

    mailVC.mailComposeDelegate = self.mailComposeDelegate

    viewController.present(mailVC, animated: true, completion: nil)
  }
}
