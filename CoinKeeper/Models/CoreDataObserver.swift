//
//  CoreDataObserver.swift
//  DropBit
//
//  Created by Ben Winters on 10/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import CoreData
import Foundation

protocol CoreDataObserver: AnyObject {
  func setContextNotificationTokens(willSaveToken: NotificationToken, didSaveToken: NotificationToken)
  func handleWillSaveContext(_ context: NSManagedObjectContext)
  func handleDidSaveContext(_ context: NSManagedObjectContext)
}

extension CoreDataObserver {

  func observeContextSaveNotifications(forContext context: NSManagedObjectContext) {
    let willSaveToken = willSaveNotificationToken(forContext: context)
    let didSaveToken = didSaveContextNotificationToken(forContext: context)
    setContextNotificationTokens(willSaveToken: willSaveToken, didSaveToken: didSaveToken)
  }

  private func willSaveNotificationToken(forContext context: NSManagedObjectContext) -> NotificationToken {
    let willSaveToken = NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextWillSave,
      object: context,
      queue: nil,
      using: { [weak self] notification in
        guard let context = notification.object as? NSManagedObjectContext else { return }
        self?.handleWillSaveContext(context)
    })

    return NotificationToken(notificationCenter: .default, token: willSaveToken)
  }

  private func didSaveContextNotificationToken(forContext context: NSManagedObjectContext) -> NotificationToken {
    let didSaveToken = NotificationCenter.default.addObserver(
      forName: .NSManagedObjectContextDidSave,
      object: context,
      queue: nil,
      using: { [weak self] notification in
        guard let context = notification.object as? NSManagedObjectContext else { return }
        self?.handleDidSaveContext(context)
    })
    return NotificationToken(notificationCenter: .default, token: didSaveToken)
  }

}
