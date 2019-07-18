//
//  UIView+Xib.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/13/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol XibViewType: AnyObject {
  var xibName: String { get }
  func xibSetup()
}

extension UIView: XibViewType {
  @objc var xibName: String { return String(describing: type(of: self)) }

  func xibSetup() {
    guard let view = fromNib() else { return }
    view.backgroundColor = .clear
    view.frame = bounds
    view.translatesAutoresizingMaskIntoConstraints = false
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(view)
    view.topAnchor.constraint(equalTo: topAnchor).isActive = true
    view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
  }

  fileprivate func fromNib() -> UIView? {
    let nibName = xibName
    let bundle = Bundle(for: type(of: self))
    let nib = UINib(nibName: nibName, bundle: bundle)
    let view = nib.instantiate(withOwner: self, options: nil).first as? UIView
    return view
  }
}

protocol ReusableView: AnyObject {
  static var reuseIdentifier: String { get }
  static func nib() -> UINib
}

extension ReusableView {
  static var reuseIdentifier: String {
    return String(describing: self)
  }

  static func nib() -> UINib {
    return UINib(nibName: reuseIdentifier, bundle: nil)
  }
}

extension UIView: ReusableView {}

extension UIView {

  /// e.g. let myView: MyView = MyView.fromNib()
  class func fromNib<T: UIView>() -> T {
    guard let view = Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)?.first as? T else {
      return T()
    }
    return view
  }

}
