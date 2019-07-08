//
//  VerifyRecoveryWordsViewController.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol VerifyRecoveryWordsViewControllerDelegate: AnyObject {
  func viewController(_ viewController: UIViewController, didSuccessfullyVerifyWords words: [String])
  func viewController(_ viewController: UIViewController, didSkipBackingUpWords words: [String])
  func viewControllerFailedWordVerification(_ viewController: UIViewController)
  func viewControllerWordVerificationMaxFailuresAttempted(_ viewController: UIViewController)
}

final class VerifyRecoveryWordsViewController: BaseViewController, StoryboardInitializable {

  static func newInstance(withDelegate delegate: VerifyRecoveryWordsViewControllerDelegate,
                          recoveryWords words: [String]) -> VerifyRecoveryWordsViewController {
    let controller = VerifyRecoveryWordsViewController.makeFromStoryboard()
    controller.generalCoordinationDelegate = delegate
    controller.recoveryWords = words
    return controller
  }

  // MARK: outlets
  @IBOutlet var titleLabel: OnboardingTitleLabel!
  @IBOutlet var closeButton: UIButton!
  @IBOutlet var subtitleLabel: OnboardingSubtitleLabel!
  @IBOutlet var verificationCollectionView: UICollectionView! {
    didSet {
      verificationCollectionView.backgroundColor = .clear
      verificationCollectionView.showsHorizontalScrollIndicator = false
      verificationCollectionView.isScrollEnabled = false
    }
  }

  // MARK: variables
  var viewModel: VerifyRecoveryWordsViewModelType?
  var verificationCollectionViewDDS: VerifyRecoveryWordsCollectionViewDDS?
  var recoveryWords: [String] = [] {
    didSet {
      self.viewModel = VerifyRecoveryWordsViewModel(words: recoveryWords, resultDelegate: self)
      let dataObjects = self.viewModel?.dataObjectsForVerification(withDelegate: self)
      self.verificationCollectionViewDDS = dataObjects.flatMap { VerifyRecoveryWordsCollectionViewDDS(dataObjects: $0) }
    }
  }
  var coordinationDelegate: VerifyRecoveryWordsViewControllerDelegate? {
    return generalCoordinationDelegate as? VerifyRecoveryWordsViewControllerDelegate
  }

  // MARK: private variables
  private lazy var itemSize: CGSize = {
    return CGSize(width: self.view.frame.width, height: 392.0)
  }()

  // MARK: view lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    (verificationCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize = itemSize
    verificationCollectionView.registerNib(cellType: VerifyRecoveryWordCell.self)
    verificationCollectionView.dataSource = verificationCollectionViewDDS
    verificationCollectionView.reloadData()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationItem.rightBarButtonItem = nil
    closeButton.isHidden = false
  }

  @objc func skipBackupRecoveryWords() {
    coordinationDelegate?.viewController(self, didSkipBackingUpWords: recoveryWords)
  }

  @IBAction func closeButtonTapped() {
    dismiss(animated: true, completion: nil)
  }
}

extension VerifyRecoveryWordsViewController: VerifyRecoveryWordSelectionDelegate {
  func cell(_ cell: VerifyRecoveryWordCell, didSelectWord word: String, withCellData cellData: VerifyRecoveryWordCellData) {
    viewModel?.checkMatch(forWord: word, cellData: cellData)
  }
}

extension VerifyRecoveryWordsViewController: VerifyRecoveryWordsResultDelegate {
  func firstMatchFound() {
    let nextIndexPath = IndexPath(item: 1, section: 0)
    verificationCollectionView.layoutIfNeeded()
    verificationCollectionView.scrollToItem(at: nextIndexPath, at: .centeredHorizontally, animated: true)
  }

  func secondMatchFound() {
    coordinationDelegate?.viewController(self, didSuccessfullyVerifyWords: recoveryWords)
  }

  func errorFound() {
    coordinationDelegate?.viewControllerFailedWordVerification(self)
  }

  func fatalErrorFound() {
    coordinationDelegate?.viewControllerWordVerificationMaxFailuresAttempted(self)
  }
}
