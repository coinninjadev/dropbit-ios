//
//  SyncRoutineError.swift
//  DropBit
//
//  Created by BJ Miller on 12/18/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation

enum SyncRoutineError: Error, LocalizedError {
  case syncRoutineInProgress
  case missingRecoveryWords
  case missingWalletManager
  case notReady
  case missingWorkers
  case missingDatabaseMigrationWorker
  case missingSyncTask
  case missingQueueDelegate

  var errorDescription: String? {
    switch self {
    case .syncRoutineInProgress: return "Sync routine already in progress."
    case .missingSyncTask: return "Sync task not assigned"
    case .missingQueueDelegate: return "Serial queue delegate not assigned"
    default: return nil
    }
  }
}
