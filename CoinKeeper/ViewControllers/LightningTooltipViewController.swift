//
//  LightningTooltipViewController.swift
//  DropBit
//
//  Created by Ben Winters on 7/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class LightningTooltipViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var fauxToggleContainer: UIView!
  @IBOutlet var fauxToggleBitcoinBackgroundView: UIView!
  @IBOutlet var fauxToggleLightningBackgroundView: UIView!
  @IBOutlet var semiOpaqueBackgroundView: UIView!

  @IBOutlet var arrowImageView: UIImageView!
  @IBOutlet var contentContainerView: UIView!
  @IBOutlet var contentTitleLabel: UILabel!

  @IBOutlet var bitcoinListContainer: UIView!
  @IBOutlet var bitcoinListHeaderBackgroundView: UIView!
  @IBOutlet var bitcoinListStackView: UIStackView!

  @IBOutlet var lightningListContainer: UIView!
  @IBOutlet var lightningListHeaderBackgroundView: UIView!
  @IBOutlet var lightningListStackView: UIStackView!

  static func newInstance() -> LightningTooltipViewController {
    let vc = LightningTooltipViewController.makeFromStoryboard()
    vc.modalPresentationStyle = .overFullScreen
    vc.modalTransitionStyle = .crossDissolve
    return vc
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.view.backgroundColor = .clear
    self.semiOpaqueBackgroundView.backgroundColor = .semiOpaquePopoverBackground

    self.arrowImageView.image = UIImage(named: "triangle")?.maskWithColor(color: .extraLightGrayBackground)
    self.contentContainerView.backgroundColor = .extraLightGrayBackground

    self.contentTitleLabel.textColor = .lightningBlue
    self.contentTitleLabel.font = .regular(18)

    fauxToggleBitcoinBackgroundView.backgroundColor = .bitcoinOrange
    fauxToggleLightningBackgroundView.backgroundColor = .lightningBlue
    bitcoinListHeaderBackgroundView.backgroundColor = .bitcoinOrange
    lightningListHeaderBackgroundView.backgroundColor = .lightningBlue

    let radius: CGFloat = 6
    fauxToggleContainer.applyCornerRadius(radius)
    contentContainerView.applyCornerRadius(radius)
    bitcoinListContainer.applyCornerRadius(radius)
    lightningListContainer.applyCornerRadius(radius)

    setupToggleTitleViews()
    setupListItems()
    setupTappableOverlay()
  }

  private func setupToggleTitleViews() {
    let bitcoinToggleTitle = ToggleBitcoinTitleView(frame: .zero)
    addSubviewWithCenteringConstraints(bitcoinToggleTitle, to: fauxToggleBitcoinBackgroundView)

    let bitcoinListTitle = ToggleBitcoinTitleView(frame: .zero)
    addSubviewWithCenteringConstraints(bitcoinListTitle, to: bitcoinListHeaderBackgroundView)

    let lightningToggleTitle = ToggleLightningTitleView(frame: .zero)
    addSubviewWithCenteringConstraints(lightningToggleTitle, to: fauxToggleLightningBackgroundView)

    let lightningListTitle = ToggleLightningTitleView(frame: .zero)
    addSubviewWithCenteringConstraints(lightningListTitle, to: lightningListHeaderBackgroundView)
  }

  private func addSubviewWithCenteringConstraints(_ subview: UIView, to view: UIView) {
    view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(subview)
    NSLayoutConstraint.activate([
      subview.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      subview.centerXAnchor.constraint(equalTo: view.centerXAnchor)
      ]
    )
  }

  private func setupListItems() {
    let bitcoinItems: [LightningTooltipListItem] = [
      LightningTooltipListItem(imageName: "lightningTooltipBitcoinAmount", text: "SENDING OVER $200"),
      LightningTooltipListItem(imageName: "lightningTooltipBitcoinSpeed", text: "SLOWER"),
      LightningTooltipListItem(imageName: "lightningTooltipBitcoinFees", text: "HIGHER FEES")
    ]

    let lightningItems: [LightningTooltipListItem] = [
      LightningTooltipListItem(imageName: "lightningTooltipLightningAmount", text: "SENDING UNDER $200"),
      LightningTooltipListItem(imageName: "lightningTooltipLightningSpeed", text: "FAST"),
      LightningTooltipListItem(imageName: "lightningTooltipLightningFees", text: "LOW FEES")
    ]

    bitcoinItems.forEach { self.bitcoinListStackView.addArrangedSubview($0) }
    lightningItems.forEach { self.lightningListStackView.addArrangedSubview($0) }
  }

  private func setupTappableOverlay() {
    let tappableOverlay = UIView()
    tappableOverlay.translatesAutoresizingMaskIntoConstraints = false
    tappableOverlay.backgroundColor = .clear
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissViewController))
    tappableOverlay.addGestureRecognizer(tapGesture)
    self.view.addSubview(tappableOverlay)
    NSLayoutConstraint.activate([
      tappableOverlay.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
      tappableOverlay.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
      tappableOverlay.topAnchor.constraint(equalTo: self.view.topAnchor),
      tappableOverlay.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
      ]
    )
  }

  @objc func dismissViewController() {
    self.dismiss(animated: true, completion: nil)
  }

}
