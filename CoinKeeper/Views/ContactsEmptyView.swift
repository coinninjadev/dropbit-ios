//
//  ContactsEmptyView.swift
//  DropBit
//
//  Created by Ben Winters on 5/24/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol ContactsEmptyViewDelegate: AnyObject {
  func viewDidSelectPrimaryAction(_ view: UIView)
}

class ContactsEmptyView: UIView {

  weak var delegate: ContactsEmptyViewDelegate?

  @IBOutlet var descriptionLabel: UILabel!
  @IBOutlet var primaryButton: PrimaryActionButton!
  @IBAction func performPrimaryAction(_ sender: Any) {
    delegate?.viewDidSelectPrimaryAction(self)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initialize()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initialize()
  }

  private func initialize() {
    xibSetup()
    backgroundColor = .clear
    descriptionLabel.text = "Your contacts will be shown here once you allow DropBit to access them."
    descriptionLabel.textColor = Theme.Color.grayText.color
    descriptionLabel.font = CKFont.regular(14)
    primaryButton.setTitle("ALLOW ACCESS TO CONTACTS", for: .normal)
  }

}
