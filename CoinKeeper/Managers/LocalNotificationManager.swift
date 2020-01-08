//
//  LocalNotificationManager.swift
//  DropBit
//
//  Created by Mitchell Malleo on 1/6/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UserNotifications

enum LocalNotificationType: String, CaseIterable {
  case backupWords

  var title: String {
    switch self {
    case .backupWords: return "Reminder"
    }
  }

  var detail: String {
    switch self {
    case .backupWords: return "Backup your wallet now so if you lose your phone you don’t lose your Bitcoin."
    }
  }

  var hours: Int {
    switch self {
    case .backupWords: return 48
    }
  }
}

protocol LocalNotificationManagerType {
  func schedule(_ type: LocalNotificationType)
  func unschedule(_ type: LocalNotificationType)
  func unscheduleAll()
}

class LocalNotificationManager: LocalNotificationManagerType {

  func schedule(_ type: LocalNotificationType) {
    let content = UNMutableNotificationContent()
    content.title = type.title
    content.body = type.detail

    let date = Calendar.current.date(byAdding: .hour, value: type.hours, to: Date()) ?? Date()
    let components = Calendar.current.dateComponents([.second, .minute, .hour, .day], from: date)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

    let request = UNNotificationRequest(identifier: type.rawValue,
                content: content, trigger: trigger)
    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
  }

  func unschedule(_ type: LocalNotificationType) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [type.rawValue])
  }

  func unscheduleAll() {
    for type in LocalNotificationType.allCases {
      unschedule(type)
    }
  }

}
