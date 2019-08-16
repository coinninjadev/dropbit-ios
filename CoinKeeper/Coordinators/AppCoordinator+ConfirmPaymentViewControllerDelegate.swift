//
//  AppCoordinator+ConfirmPaymentViewControllerDelegate.swift
//  CoinKeeper
//
//  Created by Mitchell on 4/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import CNBitcoinKit
import Result
import CoreData
import MessageUI
import PromiseKit

struct LightningPaymentInputs {
  let sats: Int
  let invoice: String
  let sharedPayload: SharedPayloadDTO?
}

extension AppCoordinator: ConfirmPaymentViewControllerDelegate, CurrencyFormattable {

  func confirmPaymentViewControllerDidLoad(_ viewController: UIViewController) {
    analyticsManager.track(event: .confirmScreenLoaded, with: nil)
  }

  private func presentPinEntryViewController(_ pinEntryVC: PinEntryViewController) {
    pinEntryVC.modalPresentationStyle = .overFullScreen
    navigationController.topViewController()?.present(pinEntryVC, animated: true, completion: nil)
  }

  func viewControllerDidConfirmLightningPayment(_ viewController: UIViewController, inputs: LightningPaymentInputs) {
    // TODO: add logic to check amount limits
    let viewModel = PaymentVerificationPinEntryViewModel(amountDisablesBiometrics: false)
    let successHandler: CKCompletion = { [unowned self] in
      self.handleSuccessfulLightningPaymentVerification(with: inputs)
    }

    let pinEntryVC = PinEntryViewController.newInstance(delegate: self,
                                                        viewModel: viewModel,
                                                        success: successHandler)
    presentPinEntryViewController(pinEntryVC)
  }

  func viewControllerDidConfirmOnChainPayment(
    _ viewController: UIViewController,
    transactionData: CNBTransactionData,
    rates: ExchangeRates,
    outgoingTransactionData: OutgoingTransactionData
    ) {
    biometricsAuthenticationManager.resetPolicy()

    let converter = CurrencyConverter(fromBtcTo: .USD,
                                      fromAmount: NSDecimalNumber(integerAmount: outgoingTransactionData.amount, currency: .BTC),
                                      rates: rates)
    let amountInfo = SharedPayloadAmountInfo(converter: converter)
    var outgoingTxDataWithAmount = outgoingTransactionData
    outgoingTxDataWithAmount.sharedPayloadDTO?.amountInfo = amountInfo

    let senderIdentityFactory = SenderIdentityFactory(persistenceManager: persistenceManager)
    let senderIdentity = senderIdentityFactory.preferredSharedPayloadSenderIdentity(forDropBitType: outgoingTransactionData.dropBitType)
    outgoingTxDataWithAmount.sharedPayloadSenderIdentity = senderIdentity

    let usdThreshold = 100_00
    let shouldDisableBiometrics = amountInfo.fiatAmount > usdThreshold

    let pinEntryViewModel = PaymentVerificationPinEntryViewModel(amountDisablesBiometrics: shouldDisableBiometrics)

    let successHandler: CKCompletion = { [unowned self] in
      self.analyticsManager.track(event: .preBroadcast, with: nil)
      self.handleSuccessfulOnChainPaymentVerification(with: transactionData, outgoingTransactionData: outgoingTxDataWithAmount)
    }

    let pinEntryVC = PinEntryViewController.newInstance(delegate: self,
                                                        viewModel: pinEntryViewModel,
                                                        success: successHandler)
    presentPinEntryViewController(pinEntryVC)
  }

  func viewControllerDidConfirmInvite(_ viewController: UIViewController,
                                      outgoingInvitationDTO: OutgoingInvitationDTO,
                                      walletTxType: WalletTransactionType) {
    biometricsAuthenticationManager.resetPolicy()
    let pinEntryViewModel = InviteVerificationPinEntryViewModel()

    let successHandler: CKCompletion = { [unowned self] in
      guard outgoingInvitationDTO.fee > 0 else {
        log.error("DropBit invitation fee is zero")
        self.handleFailure(error: TransactionDataError.insufficientFee)
        return
      }

      let receiverBody = outgoingInvitationDTO.contact.userIdentityBody

      let senderIdentityFactory = SenderIdentityFactory(persistenceManager: self.persistenceManager)
      guard let senderBody = senderIdentityFactory.preferredSenderBody(forReceiverType: receiverBody.identityType) else {
        log.error("Failed to create sender body")
        return
      }

      let inviteBody = RequestAddressBody(amount: outgoingInvitationDTO.btcPair,
                                          receiver: receiverBody,
                                          sender: senderBody,
                                          requestId: UUID().uuidString.lowercased())
      self.handleSuccessfulInviteVerification(with: inviteBody, outgoingInvitationDTO: outgoingInvitationDTO)
    }

    let pinEntryVC = PinEntryViewController.newInstance(delegate: self,
                                                        viewModel: pinEntryViewModel,
                                                        success: successHandler)
    presentPinEntryViewController(pinEntryVC)
  }

  func viewControllerRequestedShowFeeTooExpensiveAlert(_ viewController: UIViewController) {
    let message = """
    In order to use this fee option you must adjust the amount you are sending.
    The current amount you are sending with the cost of this fee is more than you have in your wallet.
    """
    let alert = alertManager.defaultAlert(withTitle: "Insufficient Funds", description: message)
    viewController.present(alert, animated: true, completion: nil)
  }

  func viewControllerDidRetryPayment() {
    analyticsManager.track(event: .retryFailedPayment, with: nil)
  }

  private func handleSuccessfulInviteVerification(with inviteBody: RequestAddressBody, outgoingInvitationDTO: OutgoingInvitationDTO) {

    // guard against fee at 0 again, to really ensure that it is not zero before creating the network request
    guard outgoingInvitationDTO.fee > 0 else {
      log.error("DropBit invitation fee is zero")
      handleFailure(error: TransactionDataError.insufficientFee)
      return
    }
    let bgContext = persistenceManager.createBackgroundContext()
    let successFailViewController = SuccessFailViewController.newInstance(viewModel: PaymentSuccessFailViewModel(mode: .pending),
                                                                          delegate: self)
    bgContext.performAndWait {
      persistenceManager.brokers.invitation.persistUnacknowledgedInvitation(
        withDTO: outgoingInvitationDTO,
        acknowledgmentId: inviteBody.requestId,
        in: bgContext)

      do {
        try bgContext.save()
      } catch {
        log.contextSaveError(error)
      }
    }
    successFailViewController.action = { [weak self] in
      guard let strongSelf = self else { return }

      strongSelf.networkManager.createAddressRequest(body: inviteBody)
        .done(in: bgContext) { response in
          strongSelf.handleAddressRequestCreationSuccess(response: response,
                                                         invitationDTO: outgoingInvitationDTO,
                                                         successFailVC: successFailViewController,
                                                         in: bgContext)
          // Call this separately from handleAddressRequestCreationSuccess so
          // that it doesn't interrupt Twilio error SMS fallback flow
          strongSelf.showShareTransactionIfAppropriate(dropBitType: outgoingInvitationDTO.contact.dropBitType)

        }.catch(on: .main) { error in
          strongSelf.handleAddressRequestCreationError(error,
                                                       invitationDTO: outgoingInvitationDTO,
                                                       inviteBody: inviteBody,
                                                       successFailVC: successFailViewController,
                                                       in: bgContext)
      }
    }

    self.navigationController.topViewController()?.present(successFailViewController, animated: false) {
      successFailViewController.action?()
    }
  }

  private func handleAddressRequestCreationSuccess(response: WalletAddressRequestResponse,
                                                   invitationDTO: OutgoingInvitationDTO,
                                                   successFailVC: SuccessFailViewController,
                                                   in context: NSManagedObjectContext) {
    context.performAndWait {
      self.acknowledgeSuccessfulInvite(outgoingInvitationDTO: invitationDTO, response: response, in: context)
      do {
        try context.save()
        successFailVC.setMode(.success)

        // When TweetMethodViewController requests DropBit send the tweet,
        // we need to pass the resulting tweet ID back to the SuccessFailViewController,
        // which doesn't have a direct relationship to the TweetMethodViewController.
        let tweetCompletion: TweetCompletionHandler = { [weak successFailVC] (tweetId: String?) in
          guard let id = tweetId, tweetId != WalletAddressRequestResponse.duplicateDeliveryID else { return }
          let twitterURL = URL(string: TwitterEndpoints.tweetURL(id).urlString)
          successFailVC?.setURL(twitterURL)
        }

        if case let .twitter(twitterContact) = invitationDTO.contact.dropBitType {
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let topVC = self.navigationController.topViewController() {
              let tweetMethodVC = TweetMethodViewController.newInstance(twitterRecipient: twitterContact,
                                                                        addressRequestResponse: response,
                                                                        tweetCompletion: tweetCompletion,
                                                                        delegate: self)
              topVC.present(tweetMethodVC, animated: true, completion: nil)
            }
          }
        }

      } catch {
        log.contextSaveError(error)
        successFailVC.setMode(.failure)
        self.handleFailureInvite(error: error)
      }
    }
  }

  private func handleAddressRequestCreationError(_ error: Error,
                                                 invitationDTO: OutgoingInvitationDTO,
                                                 inviteBody: RequestAddressBody,
                                                 successFailVC: SuccessFailViewController,
                                                 in context: NSManagedObjectContext) {
    if let networkError = error as? CKNetworkError,
      case let .twilioError(response) = networkError,
      let typedResponse = try? response.map(WalletAddressRequestResponse.self, using: WalletAddressRequestResponse.decoder) {

      self.handleAddressRequestCreationSuccess(response: typedResponse,
                                               invitationDTO: invitationDTO,
                                               successFailVC: successFailVC,
                                               in: context)
      // Dismisses both the SuccessFailVC and the ConfirmPaymentVC before showing alert
      self.viewController(successFailVC, success: true) {
        self.showManualInviteSMSAlert(inviteBody: inviteBody)
      }

    } else {
      // In the edge case where we don't receive a server response due to a network failure, expected behavior
      // is that the SharedPayloadDTO is never persisted or sent, because we don't create CKMTransaction dependency
      // until we have acknowledgement from the server that the address request was successfully posted.
      self.handleFailureInvite(error: error)
      successFailVC.setMode(.failure)
    }
  }

  private func createInviteNotificationSMSComposer(for inviteBody: RequestAddressBody) -> MFMessageComposeViewController? {
    guard MFMessageComposeViewController.canSendText(),
      let phoneNumber = inviteBody.receiver.globalNumber()
      else { return nil }

    let composeVC = MFMessageComposeViewController()
    composeVC.messageComposeDelegate = self.messageComposeDelegate
    composeVC.recipients = [phoneNumber.asE164()]
    let downloadURL = CoinNinjaUrlFactory.buildUrl(for: .download)?.absoluteString ?? ""
    let amount = NSDecimalNumber(integerAmount: inviteBody.amount.usd, currency: .USD)
    let amountDesc = amountStringWithSymbol(amount, .USD)
    composeVC.body = """
      I just sent you \(amountDesc) in Bitcoin.
      Download the DropBit app to claim it. \(downloadURL)
      """.removingMultilineLineBreaks()
    return composeVC
  }

  private func showManualInviteSMSAlert(inviteBody: RequestAddressBody) {
    let requestConfiguration = AlertActionConfiguration(title: "NOTIFY", style: .default, action: { [weak self] in
      guard let strongSelf = self,
        let composeVC = strongSelf.createInviteNotificationSMSComposer(for: inviteBody),
        let topVC = strongSelf.navigationController.topViewController() else {
          return
      }
      topVC.present(composeVC, animated: true, completion: nil)
    })

    let formatter = CKPhoneNumberFormatter(format: .international)

    var recipientDesc = "the recipient"
    if let globalNumber = inviteBody.receiver.globalNumber(),
      let formattedNumber = try? formatter.string(from: globalNumber) {
      recipientDesc = formattedNumber
    }

    let description = "Success! Let \(recipientDesc) know they have Bitcoin waiting for them."
    let alert = alertManager.detailedAlert(withTitle: nil, description: description,
                                           image: #imageLiteral(resourceName: "roundedAppIcon"), style: .standard, action: requestConfiguration)
    let topVC = self.navigationController.topViewController()
    topVC?.present(alert, animated: true, completion: nil)
  }

  private func handleFailureInvite(error: Error) {
    analyticsManager.track(event: .dropbitInitiationFailed, with: nil)
    log.error(error, message: "DropBit invite failed")

    var errorMessage = ""

    if let networkError = error as? CKNetworkError, case .rateLimitExceeded = networkError {
      errorMessage = "For security reasons we must limit the number of DropBits sent too rapidly.  Please briefly wait and try sending again."

    } else if let txDataError = error as? TransactionDataError, case .insufficientFee = txDataError {
      errorMessage = (error as? TransactionDataError)?.messageDescription ?? ""

    } else {
      errorMessage = "Oops something went wrong, try again later"
    }

    let alert = alertManager.defaultAlert(withTitle: "Error", description: errorMessage)
    self.navigationController.topViewController()?.present(alert, animated: true, completion: nil)
  }

  private func acknowledgeSuccessfulInvite(outgoingInvitationDTO: OutgoingInvitationDTO,
                                           response: WalletAddressRequestResponse,
                                           in context: NSManagedObjectContext) {
    analyticsManager.track(event: .dropbitInitiated, with: nil)
    context.performAndWait {
      let outgoingTransactionData = OutgoingTransactionData(
        txid: CKMTransaction.invitationTxidPrefix + response.id,
        dropBitType: outgoingInvitationDTO.contact.dropBitType,
        destinationAddress: "",
        amount: outgoingInvitationDTO.btcPair.btcAmount.asFractionalUnits(of: .BTC),
        feeAmount: outgoingInvitationDTO.fee,
        sentToSelf: false,
        requiredFeeRate: nil,
        sharedPayloadDTO: outgoingInvitationDTO.sharedPayloadDTO
      )
      self.persistenceManager.brokers.invitation.acknowledgeInvitation(with: outgoingTransactionData, response: response, in: context)
    }
  }

  private func handleSuccessfulLightningPaymentVerification(with inputs: LightningPaymentInputs) {
    let viewModel = PaymentSuccessFailViewModel(mode: .pending)
    let successFailVC = SuccessFailViewController.newInstance(viewModel: viewModel, delegate: self)
    let errorHandler: CKErrorCompletion = self.paymentErrorHandler(for: successFailVC)

    successFailVC.action = { [unowned self] in
      self.executeConfirmedLightningPayment(with: inputs,
                                            success: { successFailVC.setMode(.success) },
                                            failure: errorHandler)
    }

    self.navigationController.topViewController()?.present(successFailVC, animated: false) {
      successFailVC.action?()
    }
  }

  func handleSuccessfulOnChainPaymentVerification(
    with transactionData: CNBTransactionData,
    outgoingTransactionData: OutgoingTransactionData) {

    let viewModel = PaymentSuccessFailViewModel(mode: .pending)
    let successFailVC = SuccessFailViewController.newInstance(viewModel: viewModel, delegate: self)
    let errorHandler: CKErrorCompletion = self.paymentErrorHandler(for: successFailVC)

    successFailVC.action = { [unowned self] in
      self.broadcastConfirmedOnChainTransaction(
        with: transactionData,
        outgoingTransactionData: outgoingTransactionData,
        success: { successFailVC.setMode(.success) },
        failure: errorHandler)
    }

    self.navigationController.topViewController()?.present(successFailVC, animated: false) {
      successFailVC.action?()
    }
  }

  private func handleFailure(error: Error?, action: CKCompletion? = nil) {
    var localizedDescription = ""
    if let txError = error as? TransactionDataError {
      localizedDescription = txError.messageDescription
    } else {
      localizedDescription = error?.localizedDescription ?? "Unknown error"
    }
    analyticsManager.track(error: .submitTransactionError, with: localizedDescription)
    let config = AlertActionConfiguration(title: "OK", style: .default, action: action)
    let configs = [config]
    let alert = alertManager.alert(
      withTitle: "",
      description: localizedDescription,
      image: nil,
      style: .alert,
      actionConfigs: configs)
    DispatchQueue.main.async { self.navigationController.topViewController()?.present(alert, animated: true) }
  }

  private func showShareTransactionIfAppropriate(dropBitType: OutgoingTransactionDropBitType) {
    if case .twitter = dropBitType { return }
    if self.persistenceManager.brokers.preferences.dontShowShareTransaction {
      return
    }

    if let topVC = self.navigationController.topViewController() {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        let twitterVC = ShareTransactionViewController.newInstance(delegate: self)
        topVC.present(twitterVC, animated: true, completion: nil)
      }
    }
  }

  /// Provides a completion handler to be called in the catch block of payment promise chains
  private func paymentErrorHandler(for successFailVC: SuccessFailViewController) -> CKErrorCompletion {
    let errorHandler: CKErrorCompletion = { [unowned self] error in
      if let networkError = error as? CKNetworkError,
        case let .reachabilityFailed(moyaError) = networkError {
        self.handleReachabilityError(moyaError)

      } else {
        self.handleFailure(error: error, action: {
          successFailVC.setMode(.failure)
        })
      }
    }
    return errorHandler
  }

  private func executeConfirmedLightningPayment(with inputs: LightningPaymentInputs,
                                                success: @escaping CKCompletion,
                                                failure: @escaping CKErrorCompletion) {
    //TODO: Get updated ledger and persist new entry immediately following payment
    self.networkManager.payLightningPaymentRequest(inputs.invoice, sats: inputs.sats).asVoid()
      .done(success)
      .catch(failure)
  }

  private func broadcastConfirmedOnChainTransaction(with transactionData: CNBTransactionData,
                                                    outgoingTransactionData: OutgoingTransactionData,
                                                    success: @escaping CKCompletion,
                                                    failure: @escaping CKErrorCompletion) {
    self.networkManager.updateCachedMetadata()
      .then { _ in self.networkManager.broadcastTx(with: transactionData) }
      .then { txid -> Promise<String> in
        guard let wmgr = self.walletManager else {
          return Promise(error: CKPersistenceError.missingValue(key: "wallet"))
        }
        let dataCopyWithTxid = outgoingTransactionData.copy(withTxid: txid)
        return self.networkManager.postSharedPayloadIfAppropriate(withOutgoingTxData: dataCopyWithTxid,
                                                                  walletManager: wmgr)
      }
      .get { txid in
        let context = self.persistenceManager.createBackgroundContext()

        context.performAndWait {
          let vouts = transactionData.unspentTransactionOutputs.map { CKMVout.find(from: $0, in: context) }.compactMap { $0 }
          let voutDebugDesc = vouts.map { $0.debugDescription }.joined(separator: "\n")
          log.debug("Broadcast succeeded, vouts: \n\(voutDebugDesc)")
          let persistedTransaction = self.persistenceManager.brokers.transaction.persistTemporaryTransaction(
            from: transactionData,
            with: outgoingTransactionData,
            txid: txid,
            invitation: nil,
            in: context
          )

          if let walletCopy = self.walletManager?.createWalletCopy() {
            let transactionBuilder = CNBTransactionBuilder()
            let metadata = transactionBuilder.generateTxMetadata(with: transactionData, wallet: walletCopy)
            do {
              // If sending max such that there is no change address, an error will be thrown and caught below
              let tempVout = try CKMVout.findOrCreateTemporaryVout(in: context, with: transactionData, metadata: metadata)
              tempVout.transaction = persistedTransaction
            } catch {
              log.error(error, message: "error creating temp vout")
            }
          }

          do {
            try context.save()
          } catch {
            log.contextSaveError(error)
          }
        }
      }
      .done(on: .main) { _ in
        success()

        self.showShareTransactionIfAppropriate(dropBitType: .none)

        self.analyticsManager.track(property: MixpanelProperty(key: .hasSent, value: true))
        if case .twitter = outgoingTransactionData.dropBitType {
          self.analyticsManager.track(event: .twitterSendComplete, with: nil)
        }
        self.trackIfUserHasABalance()

        self.didBroadcastTransaction()
      }.catch { error in
        let nsError = error as NSError
        let broadcastError = TransactionBroadcastError(errorCode: nsError.code)
        let context = self.persistenceManager.createBackgroundContext()
        context.performAndWait {
          let vouts = transactionData.unspentTransactionOutputs.map { CKMVout.find(from: $0, in: context) }.compactMap { $0 }
          let voutDebugDesc = vouts.map { $0.debugDescription }.joined(separator: "\n")
          let encodedTx = nsError.userInfo["encoded_tx"] as? String ?? ""
          let txid = nsError.userInfo["txid"] as? String ?? ""
          let analyticsError = "error code: \(broadcastError.rawValue) :: txid: \(txid) :: encoded_tx: \(encodedTx) :: vouts: \(voutDebugDesc)"
          log.error("broadcast failed, \(analyticsError)")
          let eventValue = AnalyticsEventValue(key: .broadcastFailed, value: analyticsError)
          self.analyticsManager.track(event: .paymentSentFailed, with: eventValue)
        }

        failure(error)
    }
  }

}
