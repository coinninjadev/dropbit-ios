//
//  AppCoordinator+ConfirmPaymentViewControllerDelegate.swift
//  DropBit
//
//  Created by Mitchell on 4/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import Result
import CoreData
import MessageUI
import PromiseKit

struct LightningPaymentInputs {
  let sats: Int
  let invoice: String
  let sharedPayload: SharedPayloadDTO?
}

extension AppCoordinator: ConfirmPaymentViewControllerDelegate {

  func confirmPaymentViewControllerDidLoad(_ viewController: UIViewController) {
    analyticsManager.track(event: .confirmScreenLoaded, with: nil)
  }

  func viewControllerDidConfirmInvite(_ viewController: UIViewController,
                                      outgoingInvitationDTO: OutgoingInvitationDTO,
                                      walletTxType: WalletTransactionType) {
    biometricsAuthenticationManager.resetPolicy()
    let pinEntryViewModel = InviteVerificationPinEntryViewModel()

    let successHandler: CKCompletion = { [unowned self] in
      if outgoingInvitationDTO.walletTxType == .onChain {
        guard outgoingInvitationDTO.fee > 0 else {
          log.error("DropBit invitation fee is zero")
          self.handleFailure(error: TransactionDataError.insufficientFee)
          return
        }
      }

      let dropBitReceiver = outgoingInvitationDTO.contact.asDropBitReceiver
      let receiverBody = outgoingInvitationDTO.contact.userIdentityBody

      guard let senderBody = self.addressRequestSenderIdentity(forReceiver: dropBitReceiver) else {
        log.error("Failed to create sender body")
        return
      }

      let inviteBody = WalletAddressRequestBody(amount: outgoingInvitationDTO.btcPair,
                                                receiver: receiverBody,
                                                sender: senderBody,
                                                requestId: UUID().uuidString.lowercased(),
                                                addressType: walletTxType.addressType)
      self.enqueueSuccessfulInviteVerification(with: inviteBody, outgoingInvitationDTO: outgoingInvitationDTO)
    }

    let pinEntryVC = PinEntryViewController.newInstance(delegate: self,
                                                        viewModel: pinEntryViewModel,
                                                        success: successHandler)
    presentPinEntryViewController(pinEntryVC)
  }

  private func enqueueSuccessfulInviteVerification(with inviteBody: WalletAddressRequestBody, outgoingInvitationDTO: OutgoingInvitationDTO) {

    let operation = AsynchronousOperation(operationType: .sendInvitation)

    let bgContext = persistenceManager.createBackgroundContext()
    let successFailVC = SuccessFailViewController.newInstance(viewModel: PaymentSuccessFailViewModel(mode: .pending),
                                                              delegate: self)

    operation.task = { [weak self, weak innerOp = operation] in
      guard let strongSelf = self, let strongOperation = innerOp else { return }
      // guard against fee at 0 again, to really ensure that it is not zero before creating the network request
      if outgoingInvitationDTO.walletTxType == .onChain {
        guard outgoingInvitationDTO.fee > 0 else {
          log.error("DropBit invitation fee is zero")
          strongSelf.handleFailure(error: TransactionDataError.insufficientFee)
          return
        }
      }

      performIn(bgContext) { [weak self] () -> Void in
        guard let strongSelf = self else { return }
        ///Create and persist an orphan CKMInvitation object, which will be "acknowledged" and linked
        ///once the WAR creation network request succeeds
        strongSelf.persistenceManager.brokers.invitation.persistUnacknowledgedInvitation(
          withDTO: outgoingInvitationDTO,
          acknowledgmentId: inviteBody.requestId,
          in: bgContext)
        ///Do not save the context here, keep it only in this context until the WAR has been created successfully.
        ///If a sync is running concurrently at just the right time, it will sometimes delete this invitation
        ///because this invitation hasn't yet been received/acknowledged by the server.
      }
      .then { () -> Promise<Void> in
        successFailVC.action = { [weak self] in
          guard let strongSelf = self else { return }
          strongSelf.createAddressRequest(body: inviteBody, outgoingInvitationDTO: outgoingInvitationDTO, in: bgContext)
            .done { output in
              strongSelf.handleAddressRequestCreationSuccess(output: output, successFailVC: successFailVC, in: bgContext)
              // Call this separately from handleAddressRequestCreationSuccess so
              // that it doesn't interrupt Twilio error SMS fallback flow
              strongSelf.showShareTransactionIfAppropriate(dropBitReceiver: output.invitationDTO.contact.asDropBitReceiver,
                                                           walletTxType: output.invitationDTO.walletTxType, delegate: strongSelf)
            }
          .catch(on: .main) { error in
            log.error(error, message: "Failed to handle successful invite verification.")
            strongSelf.handleAddressRequestCreationError(error,
                                                         invitationDTO: outgoingInvitationDTO,
                                                         inviteBody: inviteBody,
                                                         successFailVC: successFailVC,
                                                         in: bgContext)
          }
        }
        return Promise.value(())
      }
      .done(on: .main) {
        strongSelf.navigationController.topViewController()?.present(successFailVC, animated: false, completion: {
          successFailVC.action?()
        })
      }
      .catch { (error) in
        log.error(error, message: "Failed to handle successful invite verification.")
        strongSelf.handleAddressRequestCreationError(error,
                                                     invitationDTO: outgoingInvitationDTO,
                                                     inviteBody: inviteBody,
                                                     successFailVC: successFailVC,
                                                     in: bgContext)
      }.finally {
        strongOperation.finish()
      }
    }

    serialQueueManager.enqueueOperationIfAppropriate(operation, policy: .always)
  }

  private struct CreateAddressRequestOutput {
    let warResponse: WalletAddressRequestResponse
    let invitationDTO: OutgoingInvitationDTO
    let preauthResponse: LNTransactionResponse?
  }

  private func createAddressRequest(body: WalletAddressRequestBody,
                                    outgoingInvitationDTO: OutgoingInvitationDTO,
                                    in context: NSManagedObjectContext) -> Promise<CreateAddressRequestOutput> {
    switch outgoingInvitationDTO.walletTxType {
    case .onChain:
      return networkManager.createAddressRequest(body: body, preauthId: nil)
        .map { CreateAddressRequestOutput(warResponse: $0, invitationDTO: outgoingInvitationDTO, preauthResponse: nil) }

    case .lightning:
      return self.base64SharedPayload(from: body, invitationDTO: outgoingInvitationDTO)
        .then { self.networkManager.preauthorizeLightningPayment(sats: body.amount.btc, encodedPayload: $0) }
        .then { preauthResponse -> Promise<CreateAddressRequestOutput> in
          let satsValues = SatsTransferredValues(transactionType: .lightning,
                                                 isInvite: true,
                                                 lightningType: .internal)
          self.analyticsManager.track(event: .satsTransferred, with: satsValues.values)
          return self.networkManager.getOrCreateLightningAccount()
            .get(in: context) { self.persistenceManager.brokers.lightning.persistAccountResponse($0, in: context) }
            .then { _ in self.networkManager.createAddressRequest(body: body, preauthId: preauthResponse.result.id) }
            .map { CreateAddressRequestOutput(warResponse: $0, invitationDTO: outgoingInvitationDTO, preauthResponse: preauthResponse) }
      }
    }
  }

  private func base64SharedPayload(from body: WalletAddressRequestBody, invitationDTO: OutgoingInvitationDTO) -> Promise<String> {
    return Promise<String> { seal in
      let payload = try SharedPayloadV2(preauthInvitationDTO: invitationDTO, senderIdentity: body.sender)
      let payloadData = try payload.encoded()
      let encodedPayload = payloadData.base64EncodedString()
      seal.fulfill(encodedPayload)
    }
  }

  private func handleAddressRequestCreationSuccess(output: CreateAddressRequestOutput,
                                                   successFailVC: SuccessFailViewController,
                                                   in context: NSManagedObjectContext) {
      acknowledgeSuccessfulInvite(using: output, in: context)
        .then(in: context) { () -> Promise<Void> in
          try context.saveRecursively()
          return Promise.value(())
        }
        .done(on: .main) { [weak self] () -> Void in
          guard let strongSelf = self else { return }
          successFailVC.setMode(.success)

          if case let .twitter(twitterContact) = output.invitationDTO.contact.asDropBitReceiver,
            let topVC = strongSelf.navigationController.topViewController() {
            let tweetMethodVC = TweetMethodViewController.newInstance(twitterRecipient: twitterContact,
                                                                      addressRequestResponse: output.warResponse,
                                                                      delegate: strongSelf)
            topVC.present(tweetMethodVC, animated: true, completion: nil)
          }
        }
        .catch { error in
          log.contextSaveError(error)
          successFailVC.setMode(.failure)
          self.handleFailureInvite(error: error)
        }
  }

  private func createInviteNotificationSMSComposer(for inviteBody: WalletAddressRequestBody) -> MFMessageComposeViewController? {
    guard MFMessageComposeViewController.canSendText(),
      let phoneNumber = inviteBody.receiver.globalNumber()
      else { return nil }

    let composeVC = MFMessageComposeViewController()
    composeVC.messageComposeDelegate = self.messageComposeDelegate
    composeVC.recipients = [phoneNumber.asE164()]
    let downloadURL = CoinNinjaUrlFactory.buildUrl(for: .download)?.absoluteString ?? ""
    let amount = NSDecimalNumber(integerAmount: inviteBody.amount.usd, currency: .USD)
    let amountDesc = FiatFormatter(currency: .USD, withSymbol: true).string(fromDecimal: amount) ?? ""
    composeVC.body = """
      I just sent you \(amountDesc) in Bitcoin.
      Download the DropBit app to claim it. \(downloadURL)
      """.removingMultilineLineBreaks()
    return composeVC
  }

  private func showManualInviteSMSAlert(inviteBody: WalletAddressRequestBody) {
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
      errorMessage = txDataError.displayMessage

    } else {
      let dbtError = DBTErrorWrapper.wrap(error)
      errorMessage = dbtError.displayMessage
    }

    let alert = alertManager.defaultAlert(withTitle: "Error", description: errorMessage)
    self.navigationController.topViewController()?.present(alert, animated: true, completion: nil)
  }

  private func acknowledgeSuccessfulInvite(using output: CreateAddressRequestOutput,
                                           in context: NSManagedObjectContext) -> Promise<Void> {
    analyticsManager.track(event: .dropbitInitiated, with: nil)

    let response = output.warResponse
    let invitationDTO = output.invitationDTO
    let outgoingTransactionData = OutgoingTransactionData(
      txid: CKMTransaction.invitationTxidPrefix + response.id,
      destinationAddress: "",
      amount: invitationDTO.btcPair.btcAmount.asFractionalUnits(of: .BTC),
      feeAmount: invitationDTO.fee,
      sentToSelf: false,
      requiredFeeRate: nil,
      sharedPayloadDTO: invitationDTO.sharedPayloadDTO,
      sender: nil,
      receiver: OutgoingDropBitReceiver(contact: invitationDTO.contact)
    )
    return performIn(context) { [weak self] () -> Void in
      guard let strongSelf = self else { return }
      strongSelf.persistenceManager.brokers.invitation.acknowledgeInvitation(with: outgoingTransactionData, response: response, in: context)
      if let preauth = output.preauthResponse {
        //Calling this after acknowledging the invitation will allow the new CKMLNLedgerEntry
        //to attach itself to the same CKMWalletEntry as the acknowledged invitation.
        strongSelf.persistenceManager.brokers.lightning.persistPaymentResponse(preauth, in: context)
      }
    }
  }

  private func handleAddressRequestCreationError(_ error: Error,
                                                 invitationDTO: OutgoingInvitationDTO,
                                                 inviteBody: WalletAddressRequestBody,
                                                 successFailVC: SuccessFailViewController,
                                                 in context: NSManagedObjectContext) {
    let dbtError = DBTErrorWrapper.wrap(error)
    if let networkError = error as? CKNetworkError,
      case let .twilioError(response) = networkError,
      let typedResponse = try? response.map(WalletAddressRequestResponse.self, using: WalletAddressRequestResponse.decoder) {

      let output = CreateAddressRequestOutput(warResponse: typedResponse, invitationDTO: invitationDTO, preauthResponse: nil)
      self.handleAddressRequestCreationSuccess(output: output, successFailVC: successFailVC, in: context)

      // Dismisses both the SuccessFailVC and the ConfirmPaymentVC before showing alert
      self.viewController(successFailVC, success: true) {
        self.showManualInviteSMSAlert(inviteBody: inviteBody)
      }

    } else {
      // In the edge case where we don't receive a server response due to a network failure, expected behavior
      // is that the SharedPayloadDTO is never persisted or sent, because we don't create CKMTransaction dependency
      // until we have acknowledgement from the server that the address request was successfully posted.
      self.handleFailureInvite(error: dbtError)
      successFailVC.setMode(.failure)
    }
  }

}
