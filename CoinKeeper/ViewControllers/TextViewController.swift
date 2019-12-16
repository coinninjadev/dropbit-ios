//
//  TextViewController.swift
//  DropBit
//
//  Created by Mitchell on 7/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class TextViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var webView: WKWebView!

  var htmlString: String?

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  static func newInstance(htmlString: String) -> TextViewController {
    let vc = TextViewController.makeFromStoryboard()
    vc.htmlString = htmlString
    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setupUI()
  }

  func setupUI() {
    guard let htmlString = htmlString else { return }
    webView.scrollView.showsVerticalScrollIndicator = false
    webView.loadHTMLString("<font face='Montserrat-Regular' size='3  '>" + htmlString, baseURL: nil)
  }
}
