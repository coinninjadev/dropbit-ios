//
//  QRCodeGenerator.swift
//  QRCreation
//
//  Created by BJ Miller on 12/5/17.
//  Copyright © 2017 BJ Miller. All rights reserved.
//

import Foundation
import CoreImage
import UIKit

struct QRCodeGenerator {
  func image(from string: String, size: CGSize) -> UIImage? {
    let ciContext = CIContext()
    let data = string.data(using: .isoLatin1, allowLossyConversion: false)

    let filter = CIFilter(name: "CIQRCodeGenerator")
    filter?.setValue(data, forKey: "inputMessage")
    filter?.setValue("Q", forKey: "inputCorrectionLevel")

    guard let ciImage = filter?.outputImage else { return nil }
    let scaleX = size.width / ciImage.extent.size.width
    let scaleY = size.height / ciImage.extent.size.height

    let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
    let transformedCIImage = ciImage.transformed(by: scaleTransform)

    let cgImage = ciContext.createCGImage(transformedCIImage, from: transformedCIImage.extent)

    return cgImage.flatMap { UIImage(cgImage: $0) }
  }
}
