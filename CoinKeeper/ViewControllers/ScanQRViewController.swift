//
//  ScanQRViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 4/12/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import AVFoundation
import SVProgressHUD

enum AVScanErrorType {
  case noBitcoinQRCodes

  var message: String {
    switch self {
    case .noBitcoinQRCodes:
      return "Scan did not have any bitcoin QR codes"
    }
  }
}

typealias PhotoViewController = UIViewController & UIImagePickerControllerDelegate & UINavigationControllerDelegate

//swiftlint:disable class_delegate_protocol
protocol ScanQRViewControllerDelegate: PaymentRequestResolver, LightningInvoiceResolver, ViewControllerDismissable {

  /// If the scanned qrCode.btcAmount is zero, use the fallbackViewModel (whose amount should originate from the calculator amount/converter).
  func viewControllerDidScan(_ viewController: UIViewController, qrCode: OnChainQRCode,
                             walletTransactionType: WalletTransactionType, fallbackViewModel: SendPaymentViewModel?)
  func viewControllerDidScan(_ viewController: UIViewController, lightningInvoice: String, completion: @escaping CKCompletion)

  func viewControllerDidAttemptInvalidDestination(_ viewController: UIViewController, error: Error?)
  func viewControllerDidPressPhotoButton(_ viewController: PhotoViewController)
  func viewControllerHadScanFailure(_ viewController: UIViewController, error: AVScanErrorType)

}

class ScanQRViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var closeButton: UIButton!
  @IBOutlet var flashButton: UIButton!
  @IBOutlet var scanBoxImageView: UIImageView!
  @IBOutlet var photosButton: UIButton!

  var bitcoinAddressValidator: CompositeValidator = {
    return CompositeValidator<String>(validators: [StringEmptyValidator(), BitcoinAddressValidator()])
  }()

  private(set) weak var delegate: ScanQRViewControllerDelegate!

  static func newInstance(delegate: ScanQRViewControllerDelegate) -> ScanQRViewController {
    let vc = ScanQRViewController.makeFromStoryboard()
    vc.delegate = delegate
    return vc
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
    delegate.viewControllerDidSelectClose(self)
  }

  @IBAction func photoButtonWasTouched() {
    delegate.viewControllerDidPressPhotoButton(self)
  }
}

extension ScanQRViewController: UINavigationControllerDelegate {}

extension ScanQRViewController: AVCaptureMetadataOutputObjectsDelegate {

  func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    guard metadataObjects.isNotEmpty else {
      delegate?.viewControllerHadScanFailure(self, error: .noBitcoinQRCodes)
      return
    }

    let rawCodes = metadataObjects.compactMap { $0 as? AVMetadataMachineReadableCodeObject }
    let destinations = rawCodes.compactMap { $0.stringValue }
    handle(possibleDestinations: destinations)
  }

  private func handle(possibleDestinations: [String]) {
    let lightningQRCodes = possibleDestinations.compactMap { LightningURL(string: $0) }
    let bitcoinQRCodes = possibleDestinations.compactMap { OnChainQRCode(string: $0) }
    guard lightningQRCodes.isNotEmpty || bitcoinQRCodes.isNotEmpty else {
      delegate.viewControllerHadScanFailure(self, error: .noBitcoinQRCodes)
      return
    }

    if let lightningQRCode = lightningQRCodes.first, currentLockStatus != .locked {
      handle(lightningQRInvoice: lightningQRCode)
    } else if let bitcoinQRCode = bitcoinQRCodes.first {
      handle(bitcoinQRCode: bitcoinQRCode)
    }
  }

  private func handle(lightningQRInvoice lightningUrl: LightningURL) {
    if didCaptureQRCode { return }
    didCaptureQRCode = true

    SVProgressHUD.show()
    delegate.viewControllerDidScan(self, lightningInvoice: lightningUrl.invoice, completion: { [weak self] in
      SVProgressHUD.dismiss()
      self?.didCaptureQRCode = false
    })
  }

  private func handle(bitcoinQRCode qrCode: OnChainQRCode) {
    if didCaptureQRCode { return }
    didCaptureQRCode = true

    if qrCode.paymentRequestURL != nil {
      delegate.viewControllerDidScan(self, qrCode: qrCode,
                                                  walletTransactionType: .onChain, fallbackViewModel: self.fallbackPaymentViewModel)

    } else if let address = qrCode.address {
      do {
        try bitcoinAddressValidator.validate(value: address)
        delegate.viewControllerDidScan(self, qrCode: qrCode,
                                                    walletTransactionType: .onChain, fallbackViewModel: self.fallbackPaymentViewModel)
      } catch {
        delegate.viewControllerDidAttemptInvalidDestination(self, error: error)
      }
    }
  }
}

extension ScanQRViewController: UIImagePickerControllerDelegate {

  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    guard let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
        let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                  context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]),
        let ciImage = CIImage(image: pickedImage),
        let features = detector.features(in: ciImage) as? [CIQRCodeFeature] else {
          delegate.viewControllerHadScanFailure(self, error: .noBitcoinQRCodes)
          return
    }

    let qrCode = features.reduce("") { "\($0)\($1.messageString ?? "")" }
    picker.dismiss(animated: true) { [weak self] in
      self?.handle(possibleDestinations: [qrCode])
    }
  }
}
