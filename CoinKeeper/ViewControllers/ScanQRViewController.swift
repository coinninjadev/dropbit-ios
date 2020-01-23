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
import Cnlib

typealias PhotoViewController = UIViewController & UIImagePickerControllerDelegate & UINavigationControllerDelegate

//swiftlint:disable class_delegate_protocol
protocol ScanQRViewControllerDelegate: PaymentRequestResolver, LightningInvoiceResolver, ViewControllerDismissable {

  /// If the scanned qrCode.btcAmount is zero, use the fallbackViewModel (whose amount should originate from the calculator amount/converter).
  func viewControllerDidScan(_ viewController: ScanQRViewController,
                             possibleDestinations: [String],
                             fallbackViewModel: SendPaymentViewModel?,
                             completion: @escaping CKCompletion)

  func viewControllerDidAttemptInvalidDestination(_ viewController: UIViewController, error: Error?)
  func viewControllerDidPressPhotoButton(_ viewController: PhotoViewController)
  func viewControllerHadScanFailure(_ viewController: UIViewController, error: DBTError.AVScan)

}

class ScanQRViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var closeButton: UIButton!
  @IBOutlet var flashButton: UIButton!
  @IBOutlet var scanBoxImageView: UIImageView!
  @IBOutlet var photosButton: UIButton!

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
  var didCaptureQRCode = false {
    willSet {
      newValue ? captureSession.stopRunning() : captureSession.startRunning()
    }
  }

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
    guard metadataObjects.isNotEmpty else { return } //may initially be empty before a valid QR code is recognized if the phone is moving

    let rawCodes = metadataObjects.compactMap { $0 as? AVMetadataMachineReadableCodeObject }
    let destinations = rawCodes.compactMap { $0.stringValue }
    handle(destinations: destinations)
  }

  private func handle(destinations: [String]) {
    if didCaptureQRCode { return }
    didCaptureQRCode = true

    delegate.viewControllerDidScan(self, possibleDestinations: destinations,
                                   fallbackViewModel: fallbackPaymentViewModel,
                                   completion: { [weak self] in
      self?.didCaptureQRCode = false
    })
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
      self?.handle(destinations: [qrCode])
    }
  }
}
