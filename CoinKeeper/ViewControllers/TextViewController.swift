//
//  TextViewController.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/24/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class TextViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var webView: UIWebView!
  @IBOutlet var closeButton: UIButton!

  var htmlString: String?

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .white
    setupUI()
  }

  func setupUI() {
    guard let htmlString = htmlString else { return }
    webView.scrollView.showsVerticalScrollIndicator = false
    webView.loadHTMLString("<font face='Montserrat-Regular' size='2  '>" + htmlString, baseURL: nil)
    view.addSubview(webView)
  }
}
