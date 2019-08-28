//
//  NoConnectionViewController.swift
//  DropBit
//
//  Created by Mitchell on 5/21/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol NoConnectionViewControllerDelegate: AnyObject {
  func viewControllerDidRequestRetry(_ viewController: UIViewController, completion: @escaping CKCompletion)
}

class NoConnectionViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var blurViewStackImageView: UIImageView!
  @IBOutlet var noConnectionLabel: UILabel!
  @IBOutlet var retryButton: PrimaryActionButton!
  @IBOutlet var activitySpinner: UIActivityIndicatorView!

  var coordinationDelegate: NoConnectionViewControllerDelegate? {
    return generalCoordinationDelegate as? NoConnectionViewControllerDelegate
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    noConnectionLabel.font = .regular(15)
    activitySpinner.startAnimating()
    activitySpinner.isHidden = true
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    blurViewStack()
  }

  @IBAction func retryConnection(_ sender: UIButton) {
    beginUIUpdateForRetry()
    coordinationDelegate?.viewControllerDidRequestRetry(self) { [weak self] in
      self?.endUIUpdateForRetry()
    }
  }

  private func beginUIUpdateForRetry() {
    retryButton.isEnabled = false
    retryButton.isUserInteractionEnabled = false
    activitySpinner.isHidden = false
  }

  private func endUIUpdateForRetry() {
    retryButton.isEnabled = true
    retryButton.isUserInteractionEnabled = true
    activitySpinner.isHidden = true
  }

  private func blurViewStack() {
    let keyWindowLayer = UIApplication.shared.keyWindow?.layer
    let size = view.frame.size
    let renderer = UIGraphicsImageRenderer(size: size)
    let screenshot = renderer.image { keyWindowLayer?.render(in: $0.cgContext) }

    let blurRadius = 5

    guard let ciimage = CIImage(image: screenshot),
      let affineFilter = CIFilter(name: "CIAffineClamp"),
      let gaussianFilter = CIFilter(name: "CIGaussianBlur") else {
        return
    }

    affineFilter.setDefaults()
    affineFilter.setValue(ciimage, forKey: kCIInputImageKey)
    let resultClamp = affineFilter.value(forKey: kCIOutputImageKey)

    gaussianFilter.setDefaults()
    gaussianFilter.setValue(resultClamp, forKey: kCIInputImageKey)
    gaussianFilter.setValue(blurRadius, forKey: kCIInputRadiusKey)

    let ciContext = CIContext(options: nil)

    guard let result = gaussianFilter.value(forKey: kCIOutputImageKey) as? CIImage,
      let cgImage = ciContext.createCGImage(result, from: ciimage.extent) else {
        return
    }

    blurViewStackImageView.image = UIImage(cgImage: cgImage)
  }
}
