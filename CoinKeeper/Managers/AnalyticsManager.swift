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
  case hasReceived = "Has Received"
  case hasSentDropBit = "Has Sent DropBit"
  case hasReceivedDropBit = "Has Received DropBit"
  case isDropBitMeEnabled = "DropBitMe Enabled"
  case relativeWalletRange = "Relative Wallet Range"
  case platform = "platform"
  case walletVersion = "Wallet Version"
  case lightningUpgradeStarted = "Lightning Upgrade Started"
  case lightningUpgradeCompleted = "Lightning Upgrade Completed"
  case lightningUpgradedFromRestore = "Lightning Upgrade From Restore"
  case lightningUpgradedFunds = "Lightning Upgraded Funds"
  case hasLightningBalance = "Has Lightning Balance"
  case lightningLockedStatus = "Lightning Wallet Locked Status"
}

enum AnalyticsManagerEventType: String {
  case learnBitcoin = "LearnBitcoin"
  case foreignWalletAddressDetected = "ForeignWalletAddressDetected"
  case invalidServerResponse = "InvalidServerResponse"
  case preBroadcast = "BroadcastStart"
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
  case earnButtonPressed = "EarnBtn"
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
  case spendBitcoinButtonPressed = "SpendBitcoin"
  case buyBitcoinWithCreditCard = "BuyBitcoinWithCreditCard"
  case buyWithQuickPay = "BuyBitcoinQuickPay"
  case buyNowButton = "BuyNowButton"
  case quickPaySuccessReturn = "QuickPaySuccessReturn"
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
  case lightningWalletSelected = "LightningWalletSelected"
  case onChainWalletSelected = "OnChainWalletSelected"
  case onChainToLightningPressed = "OnChainToLightningPressed"
  case lightningToOnChainPressed = "LightningToOnChainPressed"
  case walletToggleTooltipPressed = "WalletToggleTooltipPressed"
  case quickReloadFive = "QuickReloadFive"
  case quickReloadTwenty = "QuickReloadTwenty"
  case quickReloadFifty = "QuickReloadFifty"
  case quickReloadOneHundred = "QuickReloadOneHundred"
  case quickReloadCustomAmount = "QuickReloadCustomAmount"
  case lightningSendPressed = "LightningSendPressed"
  case lightningReceivePressed = "LightningReceivePressed"
  case attemptedToPayInvoice = "AttemptedToPayInvoice"
  case lightningToOnChainSuccessful = "LightningToOnChainSuccessful"
  case lightningTransactionDetailsPressed = "LightningTransactionDetailsPressed"
  case onChainToLightningSuccessful = "OnChainToLightningSuccessful"
  case externalLightningInvoiceInput = "ExternalLightningInvoiceInput"
  case paymentToInvoiceFailed = "PaymentToInvoiceFailed"
  case referralLinkDetected = "ReferralLinkDetected"
  case satsTransferred = "SatsTransferred"
  case referralPaymentReceived = "ReferralPaymentReceived"

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

  case coinninjaCode = "CoinNinjaCode"
  case coinninjaMessage = "CoinNinjaMessage"
  case blockstreamInfoCode = "BlockstreamCode"
  case blockstreamInfoMessage = "BlockstreamMsg"

  case transactionType = "TransactionType"
  case isDropBitInvite = "IsDropBitInvite"
  case lightningType = "LightningType"

  case countryCode = "CountryCode"
  case referrer = "Referrer"
  case invited = "Invited"
}

struct SatsTransferredValues {
  var values: [AnalyticsEventValue]

  init(transactionType: SatsTransferredTransactionTypeValue,
       isInvite: Bool, lightningType: SatsTransferredLightningTypeValue?) {
    let transactionTypeValue = AnalyticsEventValue(key: .transactionType, value: transactionType.rawValue)
    let isInviteValue = AnalyticsEventValue(key: .isDropBitInvite, value: isInvite.description)

    values = [transactionTypeValue, isInviteValue]

    if let lightningType = lightningType {
      let lightning = AnalyticsEventValue(key: .lightningType, value: lightningType.rawValue)
      values.append(lightning)
    }

  }
}

enum SatsTransferredTransactionTypeValue: String {
  case onChain = "OnChain"
  case lightning = "Lightning"
}

enum SatsTransferredLightningTypeValue: String {
  case `internal` = "Internal"
  case external = "External"
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
