//
//  LightningTooltipViewController.swift
//  DropBit
//
//  Created by Ben Winters on 7/23/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

class LightningTooltipViewController: UIViewController {

  @IBOutlet var fauxToggleContainer: UIView!
  @IBOutlet var fauxToggleBitcoinBackgroundView: UIView!
  @IBOutlet var fauxToggleLightningBackgroundView: UIView!
  @IBOutlet var semiOpaqueBackgroundView: UIView!
  @IBOutlet var arrowImageView: UIImageView!
  @IBOutlet var contentContainerView: UIView!
  @IBOutlet var contentTitleLabel: UILabel!
  @IBOutlet var bitcoinListContainer: UIView!
  @IBOutlet var lightningListContainer: UIView!
  @IBOutlet var bitcoinListHeaderBackgroundView: UIView!
  @IBOutlet var lightningListHeaderBackgroundView: UIView!

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

    fauxToggleContainer.applyCornerRadius(6)
    bitcoinListContainer.applyCornerRadius(6)
    lightningListContainer.applyCornerRadius(6)

    setupToggleTitleViews()
  }

  private func setupToggleTitleViews() {
    let lightningListTitle = ToggleLightningTitleView(frame: .zero)
    addSubviewWithCenteringConstraints(lightningListTitle, to: lightningListHeaderBackgroundView)
    let lightingToggleTitle = ToggleLightningTitleView(frame: .zero)
    addSubviewWithCenteringConstraints(lightingToggleTitle, to: fauxToggleLightningBackgroundView)
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

}
