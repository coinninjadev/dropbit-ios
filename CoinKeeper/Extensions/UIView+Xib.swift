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
    let view = fromNib()
    view?.frame = bounds
    view?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.map(addSubview)
  }

  fileprivate func fromNib() -> UIView? {
    let nibName = xibName
    let bundle = Bundle(for: type(of: self) as AnyClass)
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
