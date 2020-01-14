//
//  AppCoordinator+HolidaySelectorViewDelegate.swift
//  DropBit
//
//  Created by Mitchell Malleo on 12/5/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import SVProgressHUD
import PromiseKit

extension AppCoordinator: HolidaySelectorViewDelegate {

  func switchUserToHoliday(_ holiday: HolidayType, failure: @escaping CKCompletion) {
    let context = persistenceManager.viewContext

    networkManager.patchHolidayType(holidayType: holiday)
      .done(on: .main) { _ in
        let user = CKMUser.find(in: context)
        user?.holidayType = holiday
        try? context.saveRecursively()
    }.catchDisplayable { error in
      self.alertManager.showError(error, forDuration: 2.0)
      failure()
    }
  }

}
