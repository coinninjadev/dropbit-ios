//
//  RBFOption.swift
//  DropBit
//
//  Created by BJ Miller on 1/8/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import Cnlib

enum RBFOption {
  case mustBeRBF
  case mustNotBeRBF
  case allowed

  var value: CNBCnlibRBFOption? {
    switch self {
    case .mustBeRBF: return CNBCnlibRBFOption(CNBCnlibMustBeRBF)
    case .mustNotBeRBF: return CNBCnlibRBFOption(CNBCnlibMustNotBeRBF)
    case .allowed: return CNBCnlibRBFOption(CNBCnlibAllowedToBeRBF)
    }
  }
}
