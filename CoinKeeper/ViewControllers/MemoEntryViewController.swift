//
//  MemoEntryViewController.swift
//  DropBit
//
//  Created by BJ Miller on 11/29/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import UIKit

protocol MemoEntryViewControllerDelegate: AnyObject {
  func viewControllerDidDismiss(_ viewController: UIViewController)
}

final class MemoEntryViewController: BaseViewController, StoryboardInitializable {

  var memo = ""

  /// completion will be executed upon dismissal of this controller. Use this to pass back the text of the memo.
  var completion: (String) -> Void = { _ in }

  @IBOutlet var backgroundOverlayView: UIView! {
    didSet {
      backgroundOverlayView.alpha = 0.85
      backgroundOverlayView.backgroundColor = .black
    }
  }
  @IBOutlet var dismissTapGestureRecognizer: UITapGestureRecognizer!
  @IBOutlet var backgroundContentImageView: UIImageView!
  @IBOutlet var textEntryContainerView: UIView! {
    didSet {
      textEntryContainerView.applyCornerRadius(15.0)
    }
  }
  @IBOutlet var textView: UITextView! {
    didSet {
      textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }
  }
  @IBOutlet var textEntryContainerViewBottomConstraint: NSLayoutConstraint!
  @IBOutlet var currentCountLabel: UILabel!
  @IBOutlet var currentCountSeparatorLabel: UILabel!
  @IBOutlet var currentCountMaxLabel: UILabel!
  @IBOutlet var countLabels: [UILabel]!

  var coordinationDelegate: MemoEntryViewControllerDelegate? {
    return generalCoordinationDelegate as? MemoEntryViewControllerDelegate
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    modalTransitionStyle = .crossDissolve
    modalPresentationStyle = .overFullScreen
  }

  var backgroundImage: UIImage?
  private let maxCharacterLimit = 130

  override func viewDidLoad() {
    super.viewDidLoad()

    view.layoutIfNeeded()
    textEntryContainerViewBottomConstraint.constant = UIScreen.main.bounds.height
    view.layoutIfNeeded()

    view.backgroundColor = .clear
    backgroundContentImageView.image = backgroundImage
    textView.text = memo

    countLabels.forEach { label in
      label.font = CKFont.regular(12)
      label.textColor = .grayText
    }
    currentCountLabel.text = "\(textView.text.count)"
    currentCountSeparatorLabel.text = "/"
    currentCountMaxLabel.text = "\(maxCharacterLimit)"
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillDisplay(_:)),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )

    textView.becomeFirstResponder()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
  }

  @IBAction func dismiss(_ sender: UITapGestureRecognizer) {
    resignFirstResponderAndDismiss()
  }

  private func resignFirstResponderAndDismiss() {
    completion(textView.text)
    textView.resignFirstResponder()
    view.layoutIfNeeded()

    textEntryContainerViewBottomConstraint.constant = UIScreen.main.bounds.height

    UIView.animate(
      withDuration: 0.3,
      animations: { self.view.layoutIfNeeded() },
      completion: { _ in self.coordinationDelegate?.viewControllerDidDismiss(self) }
    )
  }

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .memoEntry(.page))
    ]
  }

  @objc func keyboardWillDisplay(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
      let endFrame = userInfo["UIKeyboardFrameEndUserInfoKey"] as? CGRect
      else { return }
    let keyboardHeight = endFrame.size.height

    view.layoutIfNeeded()
    let padding: CGFloat = 10
    let distance = keyboardHeight + padding
    textEntryContainerViewBottomConstraint.constant = distance

    UIView.animate(withDuration: 0.3) {
      self.view.layoutIfNeeded()
    }
  }
}

extension MemoEntryViewController: UITextViewDelegate {
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    guard text != "\n" else {
      self.resignFirstResponderAndDismiss()
      return false
    }
    return (textView.text.count - range.length + text.count) <= 130
  }

  public func textViewDidChange(_ textView: UITextView) {
    currentCountLabel.text = "\(textView.text.count)"
  }
}
