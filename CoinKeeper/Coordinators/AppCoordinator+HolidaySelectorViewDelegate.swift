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

  func switchUserToHoliday(_ holiday: HolidayType, success: @escaping CKCompletion) {
    alertManager.showActivityHUD(withStatus: nil)
    let context = persistenceManager.viewContext

    networkManager.patchHolidayType(holidayType: holiday)
      .done(on: .main) { _ in
        self.alertManager.hideActivityHUD(withDelay: nil, completion: nil)
        let user = CKMUser.find(in: context)
        user?.holidayType = holiday
        try? context.saveRecursively()
        success()
    }.catch { error in
      self.alertManager.showError(message: error.localizedDescription, forDuration: 2.0)
    }
  }

}
