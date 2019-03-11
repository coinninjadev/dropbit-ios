//
//  VerifyRecoveryWordsViewController.swift
//  CoinKeeper
//
//  Created by BJ Miller on 3/6/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

enum RecoveryWordsFlow {
  case createWallet
  case settings
}

protocol VerifyRecoveryWordsViewControllerDelegate: AnyObject {
  func viewController(_ viewController: UIViewController, didSuccessfullyVerifyWords words: [String], in flow: RecoveryWordsFlow)
  func viewController(_ viewController: UIViewController, didSkipBackingUpWords words: [String], in flow: RecoveryWordsFlow)
  func viewControllerFailedWordVerification(_ viewController: UIViewController)
  func viewControllerWordVerificationMaxFailuresAttempted(_ viewController: UIViewController)
}

final class VerifyRecoveryWordsViewController: BaseViewController, StoryboardInitializable {

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

  var flow: RecoveryWordsFlow = .createWallet

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
    switch flow {
    case .createWallet:
      let skipButton = BarButtonFactory.skipButton(withTarget: self, selector: #selector(skipBackupRecoveryWords))
      navigationItem.rightBarButtonItem = skipButton
      closeButton.isHidden = true
    case .settings:
      navigationItem.rightBarButtonItem = nil
      closeButton.isHidden = false
    }
  }

  @objc func skipBackupRecoveryWords() {
    coordinationDelegate?.viewController(self, didSkipBackingUpWords: recoveryWords, in: flow)
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
    coordinationDelegate?.viewController(self, didSuccessfullyVerifyWords: recoveryWords, in: flow)
  }

  func errorFound() {
    coordinationDelegate?.viewControllerFailedWordVerification(self)
  }

  func fatalErrorFound() {
    coordinationDelegate?.viewControllerWordVerificationMaxFailuresAttempted(self)
  }
}
