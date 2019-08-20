//
//  ScanQRViewController.swift
//  CoinKeeper
//
//  Created by Mitchell Malleo on 4/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import AVFoundation
import SVProgressHUD

//swiftlint:disable class_delegate_protocol
protocol ScanQRViewControllerDelegate: PaymentRequestResolver, LightningInvoiceResolver, ViewControllerDismissable {

  /// If the scanned qrCode.btcAmount is zero, use the fallbackViewModel (whose amount should originate from the calculator amount/converter).
  func viewControllerDidScan(_ viewController: UIViewController, qrCode: OnChainQRCode,
                             walletTransactionType: WalletTransactionType, fallbackViewModel: SendPaymentViewModel?)
  func viewControllerDidScan(_ viewController: UIViewController, lightningInvoice: String, completion: @escaping CKCompletion)

  func viewControllerDidAttemptInvalidDestination(_ viewController: UIViewController, error: Error?)

}

class ScanQRViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var closeButton: UIButton!
  @IBOutlet var flashButton: UIButton!
  @IBOutlet var scanBoxImageView: UIImageView!

  var bitcoinAddressValidator: CompositeValidator = {
    return CompositeValidator<String>(validators: [StringEmptyValidator(), BitcoinAddressValidator()])
  }()

  var coordinationDelegate: ScanQRViewControllerDelegate? {
    return generalCoordinationDelegate as? ScanQRViewControllerDelegate
  }

  /**
   This view model should be set when presenting this view controller (usually reflects latest amount and fromCurrency of the calculator).
   It's btcAmount will be used if the scanned QRCode's amount is zero.
   */
  var fallbackPaymentViewModel: SendPaymentViewModel?

  var captureSession: AVCaptureSession = AVCaptureSession()
  var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
  var captureMetadataOutput = AVCaptureMetadataOutput()
  var captureDevice: AVCaptureDevice?
  var isFlashlightEnabled: Bool = false
  var didCaptureQRCode = false

  override func viewDidLoad() {
    view.backgroundColor = UIColor.black
    closeButton.setImage(UIImage(imageLiteralResourceName: "close").withRenderingMode(.alwaysTemplate), for: .normal)
    closeButton.tintColor = .white
    flashButton.setImage(UIImage(imageLiteralResourceName: "flashIcon").withRenderingMode(.alwaysTemplate), for: .normal)
    flashButton.tintColor = .white
    if let captureDevice = AVCaptureDevice.default(for: .video) {
      self.captureDevice = captureDevice
      do {
        let input = try AVCaptureDeviceInput(device: captureDevice)
        let supportedCodeTypes: [AVMetadataObject.ObjectType] = [.qr]
        captureSession.addInput(input)
        captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
        captureMetadataOutput.rectOfInterest = scanBoxImageView.bounds

        captureSession.sessionPreset = AVCaptureSession.Preset.high
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        captureSession.startRunning()
      } catch {
        log.error("Failed to capture device input: %@", privateArgs: [error.localizedDescription])
      }
    } else {
      log.error("Cannot create capture device on simulator")
    }
  }

  private func toggleFlashlight() {
    guard let device = captureDevice else {
      return
    }

    if device.hasTorch {
      do {
        try device.lockForConfiguration()

        if isFlashlightEnabled {
          device.torchMode = .off
        } else {
          device.torchMode = .on
        }

        isFlashlightEnabled = !isFlashlightEnabled
        device.unlockForConfiguration()
      } catch {
        log.error("Torch could not be used")
      }
    } else {
      log.error("Torch is not available")
    }
  }

  @IBAction func flashButtonWasTouched() {
    toggleFlashlight()
  }

  @IBAction func closeButtonWasTouched() {
    coordinationDelegate?.viewControllerDidSelectClose(self)
  }
}

extension ScanQRViewController: AVCaptureMetadataOutputObjectsDelegate {

  func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    guard metadataObjects.isNotEmpty else { return }
    let rawCodes = metadataObjects.compactMap { $0 as? AVMetadataMachineReadableCodeObject }
    let lightningQRCodes = rawCodes.compactMap { $0.stringValue }.compactMap { LightningURL(string: $0) }

    if let lightningQRCode = lightningQRCodes.first {
      handle(lightningQRInvoice: lightningQRCode)
    } else {
      let bitcoinQRCodes = rawCodes.compactMap { OnChainQRCode(readableObject: $0) }
      guard let qrCode = bitcoinQRCodes.first else { return }
      handle(bitcoinQRCode: qrCode)
    }
  }

  private func handle(lightningQRInvoice lightningUrl: LightningURL) {
    if didCaptureQRCode { return } // prevent multiple network requests for paymentRequestURL
    didCaptureQRCode = true

    SVProgressHUD.show()
    coordinationDelegate?.viewControllerDidScan(self, lightningInvoice: lightningUrl.invoice, completion: {
      SVProgressHUD.dismiss()
    })
  }

  private func handle(bitcoinQRCode qrCode: OnChainQRCode) {
    if didCaptureQRCode { return } // prevent multiple network requests for paymentRequestURL
    didCaptureQRCode = true

    if qrCode.paymentRequestURL != nil {
      coordinationDelegate?.viewControllerDidScan(self, qrCode: qrCode,
                                                  walletTransactionType: .onChain, fallbackViewModel: self.fallbackPaymentViewModel)

    } else if let address = qrCode.address {
      do {
        try bitcoinAddressValidator.validate(value: address)
        coordinationDelegate?.viewControllerDidScan(self, qrCode: qrCode,
                                                    walletTransactionType: .onChain, fallbackViewModel: self.fallbackPaymentViewModel)
      } catch {
        coordinationDelegate?.viewControllerDidAttemptInvalidDestination(self, error: error)
      }
    }
  }
}
