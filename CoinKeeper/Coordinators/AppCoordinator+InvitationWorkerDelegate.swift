//
//  AppCoordinator+InvitationWorkerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 7/22/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit

protocol InvitationWorkerDelegate: AnyObject {
  func didBroadcastTransaction()
}

extension AppCoordinator: InvitationWorkerDelegate {

  func didBroadcastTransaction() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
      self?.serialQueueManager.enqueueOptionalIncrementalSync()
    }
  }

}
