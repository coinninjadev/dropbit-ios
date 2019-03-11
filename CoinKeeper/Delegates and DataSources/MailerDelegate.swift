//
//  MailerDelegate.swift
//  DropBit
//
//  Created by BJ Miller on 2/14/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit
import MessageUI

class MailerDelegate: NSObject, MFMailComposeViewControllerDelegate {
  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
    controller.dismiss(animated: true, completion: nil)
  }
}
