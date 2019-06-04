//
//  SpendBitcoinViewController.swift
//  DropBit
//
//  Created by BJ Miller on 4/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol SpendBitcoinViewControllerDelegate: AnyObject {
  func viewControllerSpendBitcoinAroundMe(_ viewController: SpendBitcoinViewController)
  func viewControllerSpendBitcoinOnline(_ viewController: SpendBitcoinViewController)
  func viewControllerSpendGiftCards(_ viewController: SpendBitcoinViewController)
}

final class SpendBitcoinViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var headerLabel: UILabel!
  @IBOutlet var cardCollectionView: UICollectionView!
  @IBOutlet var spendAroundMeButton: PrimaryActionButton!
  @IBOutlet var spendOnlineButton: PrimaryActionButton!

  var coordinationDelegate: SpendBitcoinViewControllerDelegate? {
    return generalCoordinationDelegate as? SpendBitcoinViewControllerDelegate
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    cardCollectionView.delegate = self
    cardCollectionView.dataSource = self
    cardCollectionView.registerNib(cellType: BuySpendCardCollectionViewCell.self)
    cardCollectionView.backgroundColor = .clear

    headerLabel.textColor = Theme.Color.grayText.color
    headerLabel.font = CKFont.light(15)

    spendAroundMeButton.style = .standard
    spendOnlineButton.style = .darkBlue

    let mapPinImage = UIImage(imageLiteralResourceName: "mapPin")
    let smallMobileImage = UIImage(imageLiteralResourceName: "smallMobile")
    let font = CKFont.secondaryButtonTitle
    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: Theme.Color.lightGrayText.color
    ]
    let aroundMeString = NSAttributedString(image: mapPinImage, fontDescender: font.descender, imageSize: CGSize(width: 13, height: 20)) + "  " +
      NSAttributedString(string: "AROUND ME", attributes: attributes)
    let onlineString = NSAttributedString(image: smallMobileImage, fontDescender: font.descender, imageSize: CGSize(width: 14, height: 23)) + "  " +
      NSAttributedString(string: "ONLINE", attributes: attributes)

    spendAroundMeButton.setAttributedTitle(aroundMeString, for: .normal)
    spendOnlineButton.setAttributedTitle(onlineString, for: .normal)

    navigationController?.setNavigationBarHidden(false, animated: true)
    navigationController?.navigationBar.tintColor = Theme.Color.darkBlueButton.color
  }

  @IBAction func spendBitcoinAroundMe(_ sender: Any) {
    coordinationDelegate?.viewControllerSpendBitcoinAroundMe(self)
  }

  @IBAction func spendBitcoinOnline(_ sender: Any) {
    coordinationDelegate?.viewControllerSpendBitcoinOnline(self)
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
    coordinationDelegate?.viewControllerSpendGiftCards(self)
  }
}

extension SpendBitcoinViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath) -> CGSize {
    return collectionView.frame.size
  }
}
