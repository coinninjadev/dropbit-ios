//
//  BackupRecoveryWordsViewController.swift
//  CoinKeeper
//
//  Created by BJ Miller on 2/27/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol BackupRecoveryWordsViewControllerDelegate: AnyObject {
  func viewController(_ viewController: UIViewController, didFinishWords words: [String])
  func viewController(_ viewController: UIViewController, shouldPromptToSkipWords words: [String])
}

final class BackupRecoveryWordsViewController: BaseViewController, StoryboardInitializable {

  var wordsBackedUp: Bool = false

  // MARK: outlets
  @IBOutlet var titleLabel: OnboardingTitleLabel!
  @IBOutlet var subtitleLabel: OnboardingSubtitleLabel!

  @IBOutlet var wordCollectionView: UICollectionView! {
    didSet {
      wordCollectionView.backgroundColor = .clear
      wordCollectionView.showsHorizontalScrollIndicator = false
      wordCollectionView.isUserInteractionEnabled = false
    }
  }

  @IBOutlet var nextButton: PrimaryActionButton! {
    didSet {
      nextButton.setTitle("NEXT", for: .normal)
    }
  }

  @IBOutlet var backButton: PrimaryActionButton! {
    didSet {
      backButton.setTitle("BACK", for: .normal)
      backButton.isHidden = true
    }
  }

  @IBOutlet var closeButton: UIButton!

  // MARK: variables
  var recoveryWords: [String] = [] {
    didSet {
      wordCollectionViewDDS = BackupRecoveryWordsCollectionDDS(words: recoveryWords) { [weak self] (index) in
        self?.collectionViewDidDisplay(at: index)
      }
    }
  }
  var coordinationDelegate: BackupRecoveryWordsViewControllerDelegate? {
    return generalCoordinationDelegate as? BackupRecoveryWordsViewControllerDelegate
  }
  var wordCollectionViewDDS: BackupRecoveryWordsCollectionDDS!

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .createRecoveryWords(.page))
    ]
  }

  // MARK: view lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    wordCollectionView.registerNib(cellType: BackupRecoveryWordsCell.self)

    wordCollectionView.delegate = wordCollectionViewDDS
    wordCollectionView.dataSource = wordCollectionViewDDS
    wordCollectionView.reloadData()

    (wordCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize.width = view.frame.width
  }

  @objc func skipBackupRecoveryWords() {
    coordinationDelegate?.viewController(self, shouldPromptToSkipWords: recoveryWords)
  }

  override func viewWillAppear(_ animated: Bool) {
    collectionViewDidDisplay(at: currentIndex() ?? 0)
    closeButton.isHidden = false
    navigationItem.rightBarButtonItem = nil
  }

  // MARK: actions
  @IBAction func nextButtonTapped(_ sender: UIButton) {
    if let currentIndex = currentIndex(), indexIsLast(index: currentIndex) {
      coordinationDelegate?.viewController(self, didFinishWords: recoveryWords)
    } else {
      showItem(direction: .next)
    }
  }

  @IBAction func closeButtonTapped(_ sender: UIButton) {
    dismiss(animated: true, completion: nil)
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    showItem(direction: .back)
  }

  func reviewAllRecoveryWords() {
    let path = indexPath(for: 0)
    wordCollectionView.scrollToItem(at: path, at: .centeredHorizontally, animated: true)
  }

  // MARK: private methods
  enum Direction {
    case back, next
    var offset: Int {
      switch self {
      case .back: return -1
      case .next: return 1
      }
    }
  }

  private func showItem(direction: Direction) {
    currentIndex()
      .flatMap { $0.advanced(by: direction.offset) }
      .flatMap(self.validateIndex)
      .map(self.scrollToIndex)
  }

  private func currentIndex() -> Int? {
    return wordCollectionView.indexPathsForVisibleItems.first.flatMap { $0.row }
  }

  private func validateIndex(index: Int) -> Int? {
    return index < recoveryWords.count ? index : nil
  }

  private func indexPath(for index: Int) -> IndexPath {
    return IndexPath(item: index, section: 0)
  }

  private func scrollToIndex(index: Int) {
    // Rapidly tapping PREV button can result in a crash, so clamp the index (wjf, 2018-04)
    // Now it results in a clickable, but non-functional BACK button
    // Rapidly clicking BACK or NEXT results in a visual bug only:
    // The wider NEXT button does not appear on the left end, or the VERIFY button does not turn black on the right end.
    let clampedIndex = max(0, index)
    wordCollectionView.scrollToItem(at: indexPath(for: clampedIndex), at: .centeredHorizontally, animated: true)
  }

  private func collectionViewDidDisplay(at index: Int) {
    let finalIndexTitle = wordsBackedUp ? "FINISH" : "VERIFY"
    nextButton.setTitle(indexIsLast(index: index) ? finalIndexTitle : "NEXT", for: .normal)

    let color = indexIsLast(index: index) ? Theme.Color.darkBlueButton.color : Theme.Color.primaryActionButton.color
    nextButton.backgroundColor = color

    backButton.isHidden = !((1..<recoveryWords.count) ~= index)
  }

  private func indexIsLast(index: Int) -> Bool {
    return !((0..<recoveryWords.count - 1) ~= index)
  }
}
