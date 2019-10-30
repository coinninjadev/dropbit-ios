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
      self.handleSuccessfulInviteVerification(with: inviteBody, outgoingInvitationDTO: outgoingInvitationDTO)
    }

    let pinEntryVC = PinEntryViewController.newInstance(delegate: self,
                                                        viewModel: pinEntryViewModel,
                                                        success: successHandler)
    presentPinEntryViewController(pinEntryVC)
  }

  private func handleSuccessfulInviteVerification(with inviteBody: WalletAddressRequestBody, outgoingInvitationDTO: OutgoingInvitationDTO) {

    // guard against fee at 0 again, to really ensure that it is not zero before creating the network request
    if outgoingInvitationDTO.walletTxType == .onChain {
      guard outgoingInvitationDTO.fee > 0 else {
        log.error("DropBit invitation fee is zero")
        handleFailure(error: TransactionDataError.insufficientFee)
        return
      }
    }

    let bgContext = persistenceManager.createBackgroundContext()
    let successFailViewController = SuccessFailViewController.newInstance(viewModel: PaymentSuccessFailViewModel(mode: .pending),
                                                                          delegate: self)
    bgContext.performAndWait {
      ///Create and persist an orphan CKMInvitation object, which will be "acknowledged" and linked
      ///once the WAR creation network request succeeds
      persistenceManager.brokers.invitation.persistUnacknowledgedInvitation(
        withDTO: outgoingInvitationDTO,
        acknowledgmentId: inviteBody.requestId,
        in: bgContext)
      ///Do not save the context here, keep it only in this context until the WAR has been created successfully.
      ///If a sync is running concurrently at just the right time, it will sometimes delete this invitation
      ///because this invitation hasn't yet been received/acknowledged by the server.
    }
    successFailViewController.action = { [weak self] in
      guard let strongSelf = self else { return }

      strongSelf.createAddressRequest(body: inviteBody, walletTxType: outgoingInvitationDTO.walletTxType)
        .done(in: bgContext) { response in
          strongSelf.handleAddressRequestCreationSuccess(response: response,
                                                         invitationDTO: outgoingInvitationDTO,
                                                         successFailVC: successFailViewController,
                                                         in: bgContext)
          // Call this separately from handleAddressRequestCreationSuccess so
          // that it doesn't interrupt Twilio error SMS fallback flow
          strongSelf.showShareTransactionIfAppropriate(dropBitReceiver: outgoingInvitationDTO.contact.asDropBitReceiver,
                                                       walletTxType: outgoingInvitationDTO.walletTxType, delegate: strongSelf)

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

  private func createAddressRequest(body: WalletAddressRequestBody, walletTxType: WalletTransactionType) -> Promise<WalletAddressRequestResponse> {
    switch walletTxType {
    case .onChain:
      return networkManager.createAddressRequest(body: body)
    case .lightning:
      return networkManager.preauthorizeLightningPayment(sats: body.amount.btc)
        .then { response -> Promise<WalletAddressRequestResponse> in
          var preauthBody = body
          preauthBody.preauthId = response.result.id
          return self.networkManager.createAddressRequest(body: preauthBody)
      }
    }
  }

  private func handleAddressRequestCreationSuccess(response: WalletAddressRequestResponse,
                                                   invitationDTO: OutgoingInvitationDTO,
                                                   successFailVC: SuccessFailViewController,
                                                   in context: NSManagedObjectContext) {
    context.performAndWait {
      self.acknowledgeSuccessfulInvite(outgoingInvitationDTO: invitationDTO, response: response, in: context)
      do {
        try context.saveRecursively()
        successFailVC.setMode(.success)

        if case let .twitter(twitterContact) = invitationDTO.contact.asDropBitReceiver {
          DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let topVC = self.navigationController.topViewController() {
              let tweetMethodVC = TweetMethodViewController.newInstance(twitterRecipient: twitterContact,
                                                                        addressRequestResponse: response,
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
        destinationAddress: "",
        amount: outgoingInvitationDTO.btcPair.btcAmount.asFractionalUnits(of: .BTC),
        feeAmount: outgoingInvitationDTO.fee,
        sentToSelf: false,
        requiredFeeRate: nil,
        sharedPayloadDTO: outgoingInvitationDTO.sharedPayloadDTO,
        sender: nil,
        receiver: OutgoingDropBitReceiver(contact: outgoingInvitationDTO.contact)
      )
      self.persistenceManager.brokers.invitation.acknowledgeInvitation(with: outgoingTransactionData, response: response, in: context)
    }
  }

  private func handleAddressRequestCreationError(_ error: Error,
                                                 invitationDTO: OutgoingInvitationDTO,
                                                 inviteBody: WalletAddressRequestBody,
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

}
