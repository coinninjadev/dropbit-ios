//
//  MessageResponseTests.swift
//  DropBitTests
//
//  Created by BJ Miller on 10/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import XCTest
@testable import DropBit

class MessageResponseTests: XCTestCase, ResponseStringsTestable {
  typealias ResponseType = MessageResponse

  func testValidResponseParsesMessageResponse() {
    guard let sut = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertEqual(sut.id, "380838b1-7cb2-421b-8d1c-5d9e58b99dc7")
    XCTAssertEqual(sut.createdAt, 1531921356)
    XCTAssertEqual(sut.updatedAt, 1531921356)
    XCTAssertEqual(sut.subject, "Sample subject/title")
    XCTAssertEqual(sut.body, "Sample body/description content")
    XCTAssertEqual(sut.level, GlobalMessage.Level.info)
    XCTAssertEqual(sut.platform, GlobalMessage.Platform.all)
    XCTAssertEqual(sut.priority, 0)
    XCTAssertEqual(sut.publishedAt, 1531921356)
    XCTAssertEqual(sut.url, "https://coinninja.com")
    XCTAssertEqual(sut.version, "~> 1.0.1")
  }

  func testSortingResponsesOrdersByPriority() {
    let lowPriorityData = sampleJSON(withPriority: 5, level: .error).data(using: .utf8) ?? Data()
    let highPriorityData = sampleJSON(withPriority: 0, level: .info).data(using: .utf8) ?? Data()

    guard let lowPriority = try? MessageResponse.decoder.decode(MessageResponse.self, from: lowPriorityData),
      let highPriority = try? MessageResponse.decoder.decode(MessageResponse.self, from: highPriorityData)
      else {
        XCTFail(decodingFailureMessage)
        return
    }

    let items = [lowPriority, highPriority]
    let sorted = items.sorted()

    XCTAssertEqual(sorted.first, highPriority)
  }

  private func sampleJSON(withPriority priority: Int, level: GlobalMessage.Level = .info) -> String {
    return MessageResponse.sampleJSON
      .replacingOccurrences(of: "\"priority\": 0", with: "\"priority\": \(priority)")
      .replacingOccurrences(of: "\"level\": \"info\"", with: "\"level\": \"\(level.rawValue)\"")
  }

  func testEmptyStringThrowsError() {
    guard let sample = decodedSampleJSON() else {
      XCTFail(decodingFailureMessage)
      return
    }

    XCTAssertThrowsError(try sample.copyWithEmptyRequiredStrings().validateStringValues(), emptyStringTestMessage, { error in
      XCTAssertTrue(error.isNetworkInvalidValueError, emptyStringErrorTypeMessage)
    })
  }
}

extension MessageResponse: EmptyStringCopyable {
  func copyWithEmptyRequiredStrings() -> MessageResponse {
    return MessageResponse(id: "",
                           createdAt: self.createdAt,
                           updatedAt: self.updatedAt,
                           subject: "",
                           body: "",
                           url: "",
                           level: self.level,
                           metadata: self.metadata,
                           platform: self.platform,
                           priority: self.priority,
                           publishedAt: self.publishedAt,
                           version: "")
  }
}
