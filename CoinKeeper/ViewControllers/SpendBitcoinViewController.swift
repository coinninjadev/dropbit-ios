//
//  SpendBitcoinViewController.swift
//  DropBit
//
//  Created by BJ Miller on 4/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

final class SpendBitcoinViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var headerLabel: UILabel!
  @IBOutlet var cardCollectionView: UICollectionView!
  @IBOutlet var spendAroundMeButton: PrimaryActionButton!
  @IBOutlet var spendOnlineButton: PrimaryActionButton!

  weak var urlOpener: URLOpener?

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationController?.setNavigationBarHidden(false, animated: true)
    navigationController?.navigationBar.tintColor = Theme.Color.darkBlueButton.color

    cardCollectionView.delegate = self
    cardCollectionView.dataSource = self
    cardCollectionView.registerNib(cellType: BuySpendCardCollectionViewCell.self)
    cardCollectionView.backgroundColor = .clear

    headerLabel.textColor = Theme.Color.grayText.color
    headerLabel.font = Theme.Font.sendingBitcoinAmount.font

    spendAroundMeButton.style = .standard
    spendOnlineButton.style = .darkBlue
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setNavigationBarHidden(true, animated: true)
  }
}

extension SpendBitcoinViewController: UICollectionViewDataSource, UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeue(BuySpendCardCollectionViewCell.self, for: indexPath)
    let viewModel = BuySpendCardViewModel(
      purposeImage: UIImage(imageLiteralResourceName: "giftCard"),
      purposeText: "BUY GIFT CARDS",
      cardColor: Theme.Color.appleGreen.color,
      partnerImages: [
        UIImage(imageLiteralResourceName: "partnerAmazon"),
        UIImage(imageLiteralResourceName: "partnerTarget"),
        UIImage(imageLiteralResourceName: "partnerNike"),
        UIImage(imageLiteralResourceName: "partnerNetflix")
      ]
    )
    cell.load(with: viewModel)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

  }
}

extension SpendBitcoinViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return collectionView.frame.size
  }
}
