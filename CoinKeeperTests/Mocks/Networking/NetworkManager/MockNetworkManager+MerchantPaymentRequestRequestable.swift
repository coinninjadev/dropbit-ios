//
//  MockNetworkManager+MerchantPaymentRequestRequestable.swift
//  DropBitTests
//
//  Created by Ben Winters on 11/20/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

@testable import DropBit
import Foundation
import Result

extension MockNetworkManager: MerchantPaymentRequestRequestable {

  func getMerchantPaymentRequest(at url: URL,
                                 completion: @escaping (Result<MerchantPaymentRequestResponse, MerchantPaymentRequestError>) -> Void) {

  }

}
