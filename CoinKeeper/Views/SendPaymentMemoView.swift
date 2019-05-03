//
//  SendPaymentMemoView.swift
//  DropBit
//
//  Created by Ben Winters on 1/17/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol SendPaymentMemoViewDelegate: AnyObject {
  func didTapMemoButton()

  /// Delegate should manage selected state and call configure() with the new isShared value
  func didTapShareButton()

  func didTapSharedMemoTooltip()
}

class SendPaymentMemoView: UIView {

  @IBOutlet var topBackgroundView: UIView!
  @IBOutlet var bottomBackgroundView: UIView!

  @IBOutlet var memoLabel: UILabel!

  @IBOutlet var separatorView: UIView!
  @IBOutlet var checkboxBackgroundView: UIView!
  @IBOutlet var checkboxImage: UIImageView!
  @IBOutlet var checkboxDescriptionLabel: UILabel!

  weak var delegate: SendPaymentMemoViewDelegate?

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = .clear
    applyCornerRadius(6)
    self.layer.borderWidth = 1
    self.layer.borderColor = Theme.Color.lightGrayOutline.color.cgColor

    topBackgroundView.backgroundColor = Theme.Color.whiteBackground.color
    bottomBackgroundView.backgroundColor = Theme.Color.grayMemoBackground.color
    separatorView.backgroundColor = Theme.Color.lightGrayOutline.color

    memoLabel.font = Theme.Font.secondaryButtonTitle.font

    setupGestureRecognizers()

    checkboxBackgroundView.backgroundColor = Theme.Color.primaryActionButton.color
    checkboxBackgroundView.applyCornerRadius(3)

    checkboxDescriptionLabel.text = "Securely send this memo with your transaction"
    checkboxDescriptionLabel.textColor = Theme.Color.memoInfoText.color
    checkboxDescriptionLabel.font = Theme.Font.disclaimerText.font
  }

  func setupGestureRecognizers() {
    let memoGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.triggerMemoAction(sender:)))
    topBackgroundView.isUserInteractionEnabled = true
    topBackgroundView.addGestureRecognizer(memoGestureRecognizer)

    let toggleSharingGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.toggleSelection(sender:)))
    bottomBackgroundView.isUserInteractionEnabled = true
    bottomBackgroundView.addGestureRecognizer(toggleSharingGestureRecognizer)
  }

  @objc func triggerMemoAction(sender: UITapGestureRecognizer) {
    delegate?.didTapMemoButton()
  }

  @objc func toggleSelection(sender: UITapGestureRecognizer) {
    delegate?.didTapShareButton()
  }

  @IBAction func triggerSharedMemoTooltip(_ sender: UIButton) {
    delegate?.didTapSharedMemoTooltip()
  }

  func configure(memo: String?, isShared: Bool) {
    checkboxImage.isHidden = !isShared

    if let actualTitle = memo, actualTitle.isNotEmpty {
      memoLabel.text = actualTitle
      memoLabel.textColor = Theme.Color.darkBlueText.color
    } else {
      memoLabel.text = "Add a memo"
      memoLabel.textColor = Theme.Color.grayText.color
    }
  }

}
