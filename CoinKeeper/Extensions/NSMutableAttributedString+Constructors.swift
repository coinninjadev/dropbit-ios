//
//  NSMutableAttributedString+Constructors.swift
//  DropBit
//
//  Created by Ben Winters on 4/19/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

extension NSMutableAttributedString {

  // Basic constructors for creating a new NSMutableAttributedString, which use the appending functions internally

  public static func light(_ text: String,
                           size: CGFloat,
                           color: UIColor? = nil,
                           paragraphStyle: NSMutableParagraphStyle? = nil) -> NSMutableAttributedString {

    let mutableString = NSMutableAttributedString(string: "")
    mutableString.appendLight(text, size: size, color: color, paragraphStyle: paragraphStyle)
    return mutableString
  }

  public static func regular(_ text: String,
                             size: CGFloat,
                             color: UIColor? = nil,
                             paragraphStyle: NSMutableParagraphStyle? = nil) -> NSMutableAttributedString {

    let mutableString = NSMutableAttributedString(string: "")
    mutableString.appendRegular(text, size: size, color: color, paragraphStyle: paragraphStyle)
    return mutableString
  }

  public static func medium(_ text: String,
                            size: CGFloat,
                            color: UIColor? = nil,
                            paragraphStyle: NSMutableParagraphStyle? = nil) -> NSMutableAttributedString {

    let mutableString = NSMutableAttributedString(string: "")
    mutableString.appendMedium(text, size: size, color: color, paragraphStyle: paragraphStyle)
    return mutableString
  }

  public static func semiBold(_ text: String,
                              size: CGFloat,
                              color: UIColor? = nil,
                              paragraphStyle: NSMutableParagraphStyle? = nil) -> NSMutableAttributedString {

    let mutableString = NSMutableAttributedString(string: "")
    mutableString.appendSemiBold(text, size: size, color: color, paragraphStyle: paragraphStyle)
    return mutableString
  }

  public static func bold(_ text: String,
                          size: CGFloat,
                          color: UIColor? = nil,
                          paragraphStyle: NSMutableParagraphStyle? = nil) -> NSMutableAttributedString {

    let mutableString = NSMutableAttributedString(string: "")
    mutableString.appendBold(text, size: size, color: color, paragraphStyle: paragraphStyle)
    return mutableString
  }

  public static func space(_ text: String, spacing: Double) -> NSMutableAttributedString {
    let mutableString = NSMutableAttributedString(string: text)
    mutableString.addAttributes([.kern: spacing], range: NSRange(location: 0, length: mutableString.length))
    return mutableString
  }

  // Appending functions

  public func appendLight(_ text: String, size: CGFloat, color: UIColor? = nil, paragraphStyle: NSMutableParagraphStyle? = nil) {
    appendText(text, fontName: .montserratLight, size: size, color: color, paragraphStyle: paragraphStyle)
  }

  public func appendRegular(_ text: String, size: CGFloat, color: UIColor? = nil, paragraphStyle: NSMutableParagraphStyle? = nil) {
    appendText(text, fontName: .montserratRegular, size: size, color: color, paragraphStyle: paragraphStyle)
  }

  public func appendMedium(_ text: String, size: CGFloat, color: UIColor? = nil, paragraphStyle: NSMutableParagraphStyle? = nil) {
    appendText(text, fontName: .montserratMedium, size: size, color: color, paragraphStyle: paragraphStyle)
  }

  public func appendSemiBold(_ text: String, size: CGFloat, color: UIColor? = nil, paragraphStyle: NSMutableParagraphStyle? = nil) {
    appendText(text, fontName: .montserratSemiBold, size: size, color: color, paragraphStyle: paragraphStyle)
  }

  public func appendBold(_ text: String, size: CGFloat, color: UIColor? = nil, paragraphStyle: NSMutableParagraphStyle? = nil) {
    appendText(text, fontName: .montserratBold, size: size, color: color, paragraphStyle: paragraphStyle)
  }

  private func appendText(_ text: String,
                          fontName: FontStrings,
                          size: CGFloat,
                          color: UIColor? = nil,
                          paragraphStyle: NSMutableParagraphStyle? = nil) {
    let font = UIFont(name: fontName, size: size)
    let attrs = attributes(withFont: font, color: color, paragraphStyle: paragraphStyle)
    let attributedString = NSMutableAttributedString(string: text, attributes: attrs)
    self.append(attributedString)
  }

  private func attributes(withFont font: UIFont, color: UIColor?, paragraphStyle: NSMutableParagraphStyle?) -> [NSAttributedString.Key: AnyObject] {
    var attrs: [NSAttributedString.Key: AnyObject] = [.font: font]
    if let color = color {
      attrs[.foregroundColor] = color
    }
    if let pStyle = paragraphStyle {
      attrs[.paragraphStyle] = pStyle
    }

    return attrs
  }

  /// Default value of empty array of substrings will underline all text
  public func underlineText(substrings: [String] = []) {
    let nsFullString = NSString(string: self.string)

    if substrings.isEmpty {
      self.beginEditing()
      self.addAttribute(.underlineStyle,
                        value: NSUnderlineStyle.single.rawValue,
                        range: NSRange(location: 0, length: nsFullString.length))
      self.endEditing()
    } else {
      for substring in substrings {
        let range = nsFullString.range(of: substring)
        self.beginEditing()
        self.addAttribute(.underlineStyle, value: 1, range: range)
        self.endEditing()
      }
    }
  }

  func changeFontSize(to newFontSize: CGFloat) {
    beginEditing()
    enumerateAttribute(.font, in: NSRange(location: 0, length: self.length), options: [], using: { (value, localRange, _) in
      guard let localFont = value as? UIFont else { return }
      let newFont = localFont.withSize(newFontSize)
      removeAttribute(.font, range: localRange)
      addAttribute(.font, value: newFont, range: localRange)
    })
    endEditing()
  }

  func decreaseSizeIfNecessary(to newFontSize: CGFloat, maxWidth: CGFloat) {
    let shouldResize = self.size().width > maxWidth
    guard shouldResize else { return }
    self.changeFontSize(to: newFontSize)
  }

  func increaseSizeIfAble(to newFontSize: CGFloat, maxWidth: CGFloat) {
    let originalFits = size().width < maxWidth
    guard originalFits else { return }

    let testString = NSMutableAttributedString(attributedString: self)
    testString.changeFontSize(to: newFontSize)
    if testString.size().width < maxWidth {
      self.changeFontSize(to: newFontSize)
    }
  }

}
