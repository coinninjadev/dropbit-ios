//
//  AnalyticsManager.swift
//  DropBit
//
//  Created by BJ Miller on 3/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Mixpanel
import UIKit

enum AnalyticsManagerPropertiesType: String {
  case hasWallet = "Has Wallet"
  case phoneVerified = "Phone Verified"
  case twitterVerified = "Twitter Verified"
  case wordsBackedUp = "Backed Up"
  case hasBTCBalance = "Has BTC Balance"
  case hasSent = "Has Sent"
  case hasReceived = "Has Received"
  case hasSentDropBit = "Has Sent DropBit"
  case hasReceivedDropBit = "Has Received DropBit"
  case isDropBitMeEnabled = "DropBitMe Enabled"
  case relativeWalletRange = "Relative Wallet Range"
  case v1Wallet = "v1Wallet"
  case platform = "platform"
  case walletVersion = "Wallet Version"
  case upgradeStarted = "Upgrade Started"
  case upgradeCompleted = "Upgrade Completed"
  case upgradedFromRestore = "Upgrade From Restore"
  case upgradedFunds = "Upgraded Funds"
}

enum AnalyticsManagerEventType: String {
  case userDidOpenTutorial = "UserDidOpenTutorial"
  case foreignWalletAddressDetected = "ForeignWalletAddressDetected"
  case invalidServerResponse = "InvalidServerResponse"
  case preBroadcast = "BroadcastStart"
  case successBroadcastTransaction = "BroadcastSuccess"
  case failedToBroadcastTransaction = "TxVerificationFailure"
  case paymentSentFailed = "BroadcastFailure"
  case retryFailedPayment = "RetryFailedPayment"
  case wordsBackedup = "WordsBackedUp"
  case phoneVerified = "PhoneVerified"
  case twitterVerified = "TwitterVerified"
  case phoneAutoDeverified = "PhoneAutoDeverified"
  case skipPhoneVerification = "SkipPhoneVerification"
  case paymentToContact = "ContactSend"
  case paymentToPhoneNumber = "DropBitSend"
  case paymentToAddress = "AddressPayment"
  case failedToReceiveDropbit = "DropBitReceiveFailure"
  case failedToSendDropbit = "DropBitSendFailure"
  case deleteWallet = "DeleteWallet"
  case createWallet = "CreateWallet"
  case restoreWallet = "RestoreWallet"
  case scanQRButtonPressed = "ScanQRBtn"
  case historyButtonPressed = "HistoryBtn"
  case payButtonWasPressed = "PayBtn"
  case supportButtonPressed = "SupportBtn"
  case settingsButtonPressed = "SettingsBtn"
  case backupWordsButtonPressed = "BackupWordsBtn"
  case phoneButtonPressed = "PhoneBtn"
  case spendButtonPressed = "SpendBtn"
  case requestButtonPressed = "RequestBtn"
  case sendRequestButtonPressed = "SendRequestBtn"
  case contactsButtonPressed = "ContactsBtn"
  case scanButtonPressed = "ScanBtn"
  case pasteButtonPressed = "PasteBtn"
  case twitterButtonPressed = "TwitterBtn"
  case shareTransactionPressed = "ShareTransIDBtn"
  case cancelDropbitPressed = "CancelDropBit"
  case whatIsDropbitPressed = "WhatIsDropBit"
  case dropbitContactPressed = "DropBitPressed"
  case dropbitInitiated = "DropBitInitiated"
  case dropbitInitiationFailed = "DropBitInitiationFailed"
  case dropbitAddressProvided = "DropBitAddressProvided"
  case dropbitCompleted = "DropBitCompleted"
  case twitterSendComplete = "TwitterSendComplete"
  case dropbitInviteSMSFailed = "DropBitInviteSendSMSFailure"
  case verifyUserSMSFailed = "VerifyUserSendSMSFailure"
  case coinKeeperContactPressed = "ContactPressed"
  case balanceHistoryButtonPressed = "BalanceHistoryBtn"
  case deregisterPhoneNumber = "DeregisterPhoneNumber"
  case deregisterTwitter = "DeregisterTwitter"
  case tryAgainToDeverify = "TryAgainToDeregister"
  case syncBlockchain = "SyncBlockchainPressed"
  case viewWords = "ViewWords"
  case viewLegacyWords = "ViewLegacyWords"
  case appOpen = "AppOpen"
  case firstOpen = "FirstOpen"
  case payScreenLoaded = "PayScreenLoaded"
  case confirmScreenLoaded = "ConfirmScreenLoaded"
  case sharedPayloadSent = "SharedPayloadSent"
  case getBitcoinButtonPressed = "GetBitcoin"
  case learnBitcoinButtonPressed = "LearnBitcoin"
  case spendBitcoinButtonPressed = "SpendBitcoin"
  case buyBitcoinWithCreditCard = "BuyBitcoinWithCreditCard"
  case buyBitcoinWithGiftCard = "BuyBitcoinWithGiftCard"
  case buyBitcoinAtATM = "BuyBitcoinAtATM"
  case spendOnGiftCards = "SpendOnGiftCards"
  case spendOnAroundMe = "SpendOnAroundMe"
  case spendOnOnline = "SpendOnOnline"
  case sharePromptTwitter = "ShareViaTwitter"
  case sharePromptNextTime = "ShareNextTime"
  case sharePromptNever = "ShareNever"
  case dropBitMeDisabled = "DropBitMeDisabled"
  case dropBitMeReenabled = "DropBitMeReenabled"
  case sendTweetViaDropBit = "SendTweetViaDropBit"
  case sendTweetManually = "SendTweetManually"
  case priceButtonPressed = "PriceButtonPressed"
  case chartsOpened = "ChartsOpened"
  case newsArticleOpened = "NewsArticleOpened"
  case enteredDeactivatedWords = "EnteredDeactivatedWords"

  var id: String {
    return self.rawValue
  }
}

enum AnalyticsManagerEventKey: String {

  case broadcastFailed
  case foreignWalletAddressDetected
  case invalidServerResponse
  case sharingEnabled = "SharingEnabled"
  case errorMessage = "ErrorMsg"

  case blockChainInfoCode = "BlockCode"
  case blockChainInfoMessage = "BlockMsg"
  case blockstreamInfoCode = "BlockstreamCode"
  case blockstreamInfoMessage = "BlockstreamMsg"

  case countryCode = "CountryCode"
}

enum AnalyticsRelativeWalletRange: String {
  case none = "None"
  case underDeciMilliBTC = "UnderDeciMilliBTC"
  case underMilliBTC = "UnderMilliBTC"
  case underCentiBTC = "UnderCentiBTC"
  case underDeciBTC = "UnderDeciBTC"
  case overDeciBTC = "OverDeciBTC"

  init(satoshis: Int) {
    if satoshis == 0 {
      self = .none
    } else if satoshis < 10_000 {
      self = .underDeciMilliBTC
    } else if satoshis < 100_000 {
      self = .underMilliBTC
    } else if satoshis < 1_000_000 {
      self = .underCentiBTC
    } else if satoshis < 10_000_000 {
      self = .underDeciBTC
    } else {
      self = .overDeciBTC
    }
  }
}

extension AnalyticsRelativeWalletRange: MixpanelType {
  func isValidNestedType() -> Bool {
    return true
  }

  func equals(rhs: MixpanelType) -> Bool {
    guard let rhsValue = rhs as? AnalyticsRelativeWalletRange else { return false }
    return self == rhsValue
  }
}

struct AnalyticsEventValue {
  var key: AnalyticsManagerEventKey
  var value: String
}

protocol Property {
  associatedtype PropertyValueType

  var key: AnalyticsManagerPropertiesType { get set }
  var value: PropertyValueType { get set }
}

struct MixpanelProperty: Property {
  typealias PropertyValueType = MixpanelType

  var key: AnalyticsManagerPropertiesType
  var value: MixpanelType
}

protocol AnalyticsManagerType: AnyObject {

  func start()
  func optOut()
  func optIn()
  func track(property: MixpanelProperty)
  func track(event: AnalyticsManagerEventType, with value: AnalyticsEventValue?)
  func track(event: AnalyticsManagerEventType, with values: [AnalyticsEventValue])
  func track(error: AnalyticsManagerErrorType, with message: String)
}

class AnalyticsManager: AnalyticsManagerType {

  func start() {
    Mixpanel.initialize(token: apiKeys.analyticsKey)
    Mixpanel.mainInstance().flushInterval = 10.0
    Mixpanel.mainInstance().identify(distinctId: Mixpanel.mainInstance().distinctId)
  }

  func optOut() {
    Mixpanel.mainInstance().optOutTracking()
  }

  func optIn() {
    Mixpanel.mainInstance().optInTracking()
  }

  func track(event: AnalyticsManagerEventType, with value: AnalyticsEventValue? = nil) {
    guard let keyString = value?.key.rawValue, let mxValue = value?.value else {
      Mixpanel.mainInstance().track(event: event.id)
      return
    }

    Mixpanel.mainInstance().track(event: event.id, properties: [keyString: mxValue])
  }

  func track(property: MixpanelProperty) {
    Mixpanel.mainInstance().people?.set(property: property.key.rawValue, to: property.value)
  }

  func track(event: AnalyticsManagerEventType, with values: [AnalyticsEventValue]) {
    var castedValues: [String: String] = [:]

    for value in values {
      castedValues[value.key.rawValue] = value.value
    }

    Mixpanel.mainInstance().track(event: event.id, properties: castedValues)
  }

  func track(error: AnalyticsManagerErrorType, with message: String) {
    log.error(error, message: message)
  }
}
