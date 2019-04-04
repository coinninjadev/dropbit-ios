//
//  MessagerDelegate.swift
//  DropBit
//
//  Created by Ben Winters on 4/4/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import MessageUI

class MessagerDelegate: NSObject, MFMessageComposeViewControllerDelegate {
  func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
    controller.dismiss(animated: true, completion: nil)
  }
}
