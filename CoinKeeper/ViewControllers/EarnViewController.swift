//
//  EarnPageViewController.swift
//  DropBit
//
//  Created by Mitchell Malleo on 12/2/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol EarnViewControllerDelegate: ViewControllerDismissable, CopyToClipboardMessageDisplayable {
  func viewControllerDidPressShareButton(_ viewController: UIViewController)
  func viewControllerRestrictionsButtonWasTouched(_ viewController: UIViewController)
  func viewControllerDidSelectVerify(_ viewController: UIViewController)
}

class EarnViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var closeButton: UIButton!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var detailLabel: UILabel!
  @IBOutlet var stepsStackView: UIStackView!
  @IBOutlet var containerView: UIView!

  weak var delegate: EarnViewControllerDelegate!
  private var referralLink: String?

  static func newInstance(delegate: EarnViewControllerDelegate,
                          referralLink: String?) -> EarnViewController {
    let viewController = EarnViewController.makeFromStoryboard()
    viewController.delegate = delegate
    viewController.referralLink = referralLink
    return viewController
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
  }

  private func setupUI() {
    view.backgroundColor = .black

    titleLabel.font = .bold(26)
    titleLabel.textColor = .darkLightningBlue
    titleLabel.text = "Earn Bitcoin for you and your Friends 🎉"

    detailLabel.font = .regular(15)
    detailLabel.textColor = .darkGrayText
    detailLabel.text = "Help spread Bitcoin adoption and earn Sats at the same time! Get $1 for you and $1 for them. Here’s how…"

    containerView.applyCornerRadius(20)
    setupArrangedViewsForSteps()
    setupArrangedViewsForOther()
  }

  private func setupArrangedViewsForSteps() {
    let firstStepView = EmojiDetailView()
    firstStepView.emojiLabel.text = "😎"
    firstStepView.descriptionLabel.text = "1. Invite friends to DropBit by sending them some Sats"

    let secondStepView = EmojiDetailView()
    secondStepView.emojiLabel.text = "📱"
    secondStepView.descriptionLabel.text = "2. Make sure they verify using phone number or Twitter"

    let thirdStepView = EmojiDetailView()
    thirdStepView.emojiLabel.text = "⚡️"
    thirdStepView.descriptionLabel.text = "3. You & your friend will receive $1 in your Lightning wallet"

    stepsStackView.addArrangedSubview(firstStepView)
    stepsStackView.addArrangedSubview(secondStepView)
    stepsStackView.addArrangedSubview(thirdStepView)
  }

  private func setupArrangedViewsForOther() {
    setupDefaultUI()

    if let referralLink = referralLink {
      setupUIForVerifiedUser(link: referralLink)
    } else {
      setupUIForUnverifiedUser()
    }

    setupUIForRestrictionButton()
  }

  private func setupDefaultUI() {
    let orImage = UIImage(named: "orImage")?.withRenderingMode(.alwaysTemplate)
    let orImageView = UIImageView(image: orImage)
    orImageView.tintColor = .darkGrayBackground
    orImageView.contentMode = .scaleAspectFit
    orImageView.translatesAutoresizingMaskIntoConstraints = false
    orImageView.heightAnchor.constraint(equalToConstant: 14).isActive = true
    let shareLabel = UILabel()
    shareLabel.text = "Just share your referral link"
    shareLabel.font = .bold(18)
    shareLabel.textColor = .lightningBlue
    shareLabel.textAlignment = .center

    stepsStackView.addArrangedSubview(orImageView)
    stepsStackView.addArrangedSubview(shareLabel)
  }

  private func setupUIForRestrictionButton() {
    let restrictionsButton = UIButton()
    let restrictionTitle = NSMutableAttributedString.regular("* Restrictions apply",
                                                 size: 14, color: .lightningBlue, paragraphStyle: nil)
    restrictionTitle.underlineText()
    restrictionsButton.setAttributedTitle(restrictionTitle, for: .normal)
    restrictionsButton.addTarget(self, action: #selector(restrictionsButtonWasTouched), for: .touchUpInside)
    stepsStackView.addArrangedSubview(restrictionsButton)
  }

  private func setupUIForVerifiedUser(link referralLink: String) {
    let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(referralLabelWasTouched))
    gestureRecognizer.numberOfTapsRequired = 1

    let referralLabel = UILabel()
    referralLabel.textColor = .darkBlueText
    referralLabel.font = .regular(13)
    referralLabel.text = referralLink
    referralLabel.textAlignment = .center
    referralLabel.applyCornerRadius(4)
    referralLabel.layer.borderColor = UIColor.mediumGrayBorder.cgColor
    referralLabel.translatesAutoresizingMaskIntoConstraints = false
    referralLabel.heightAnchor.constraint(equalToConstant: 45).isActive = true
    referralLabel.layer.borderWidth = 1.0
    referralLabel.backgroundColor = .white
    referralLabel.isUserInteractionEnabled = true
    referralLabel.addGestureRecognizer(gestureRecognizer)
    stepsStackView.addArrangedSubview(referralLabel)

    let trackReferralStatusButton = PrimaryActionButton()
    trackReferralStatusButton.style = .lightning(rounded: true)
    trackReferralStatusButton.setTitle("TRACK REFERRAL STATUS", for: .normal)
    trackReferralStatusButton.translatesAutoresizingMaskIntoConstraints = false
    trackReferralStatusButton.heightAnchor.constraint(equalToConstant: 51).isActive = true
    trackReferralStatusButton.addTarget(self, action: #selector(trackReferralButtonWasTouched), for: .touchUpInside)
    stepsStackView.addArrangedSubview(trackReferralStatusButton)
  }

  private func setupUIForUnverifiedUser() {
    let button = UIButton()
    let title = NSMutableAttributedString.regular("You must be verified to generate a referral link. Verify now —>",
                                                 size: 14, color: .lightningBlue, paragraphStyle: nil)
    title.underlineText()
    button.setAttributedTitle(title, for: .normal)
    button.titleLabel?.numberOfLines = 0
    button.titleLabel?.textAlignment = .center
    button.translatesAutoresizingMaskIntoConstraints = false
    button.heightAnchor.constraint(equalToConstant: 50).isActive = true
    button.addTarget(self, action: #selector(verificationButtonWasTouched), for: .touchUpInside)
    stepsStackView.addArrangedSubview(button)
  }

  @objc func referralLabelWasTouched() {
    guard let referralLink = referralLink else { return }
    UIPasteboard.general.string = referralLink
    delegate?.viewControllerSuccessfullyCopiedToClipboard(message: "Referral added to clipboard", viewController: self)
  }

  @objc func restrictionsButtonWasTouched() {
    delegate?.viewControllerRestrictionsButtonWasTouched(self)
  }

  @objc func trackReferralButtonWasTouched() {
    guard referralLink != nil else { return }
    delegate?.viewControllerDidPressShareButton(self)
  }

  @objc func verificationButtonWasTouched() {
    delegate?.viewControllerDidSelectVerify(self)
  }

  @IBAction func closeButtonWasTouched() {
    delegate?.viewControllerDidSelectClose(self)
  }
}
