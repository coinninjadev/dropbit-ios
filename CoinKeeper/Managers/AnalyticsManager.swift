//
//  AnalyticsManager.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/30/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Mixpanel
import UIKit
import os.log

enum AnalyticsManagerPropertiesType: String {
  case hasWallet = "Has Wallet"
  case phoneVerified = "Phone Verified"
  case wordsBackedUp = "Backed Up"
  case hasBTCBalance = "Has BTC Balance"
  case hasSent = "Has Sent"
  case hasReceived = "Has Received"
  case hasSentDropBit = "Has Sent DropBit"
  case hasReceivedDropBit = "Has Received DropBit"
}

enum AnalyticsManagerEventType: String {
  case skipWordsBackedup = "SkipWordsBackedup"
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
  case shareTransactionPressed = "ShareTransIDBtn"
  case cancelDropbitPressed = "CancelDropBit"
  case whatIsDropbitPressed = "WhatIsDropBit"
  case dropbitContactPressed = "DropBitPressed"
  case dropbitInitiated = "DropBitInitiated"
  case dropbitInitiationFailed = "DropBitInitiationFailed"
  case dropbitAddressProvided = "DropBitAddressProvided"
  case dropbitCompleted = "DropBitCompleted"
  case dropbitInviteSMSFailed = "DropBitInviteSendSMSFailure"
  case verifyUserSMSFailed = "VerifyUserSendSMSFailure"
  case coinKeeperContactPressed = "ContactPressed"
  case balanceHistoryButtonPressed = "BalanceHistoryBtn"
  case deregisterPhoneNumber = "DeregisterPhoneNumber"
  case tryAgainToDeverify = "TryAgainToDeregister"
  case syncBlockchain = "SyncBlockchainPressed"
  case viewWords = "ViewWords"
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

protocol AnalyticsManagerType {

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
    let logger = OSLog(subsystem: "com.coinninja.coinkeeper.AnalyticsManager", category: "track_error")
    os_log("error name: %@, message: %@", log: logger, type: .error, error.name, message)
  }
}
