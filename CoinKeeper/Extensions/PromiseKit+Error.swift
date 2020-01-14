//
//  PromiseKit+Error.swift
//  DropBit
//
//  Created by Ben Winters on 1/14/20.
//  Copyright © 2020 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import PromiseKit

extension CatchMixin {

  @discardableResult
  func catchDisplayable(on: DispatchQueue? = conf.Q.return,
                        flags: DispatchWorkItemFlags? = nil,
                        policy: PromiseKit.CatchPolicy = conf.catchPolicy,
                        _ body: @escaping (DisplayableError) -> Void) -> PromiseKit.PMKFinalizer {

    return self.catch(on: on, flags: flags, policy: policy) { (error: Error) -> Void in
      let displayable = DisplayableErrorWrapper.wrap(error)
      body(displayable)
    }
  }
}
