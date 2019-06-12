//
//  RestoreWalletViewController.swift
//  CoinKeeper
//
//  Created by Mitchell on 7/2/18.
//  Copyright © 2018 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import CNBitcoinKit
import UIKit

protocol RestoreWalletViewControllerDelegate: class {
  func viewControllerDidSubmitWords(words: [String])
}

class RestoreWalletViewController: BaseViewController, StoryboardInitializable {

  @IBOutlet var titleLabel: OnboardingTitleLabel!
  @IBOutlet var detailLabel: OnboardingSubtitleLabel!
  @IBOutlet var selectWordLabel: UILabel! {
    didSet {
      selectWordLabel.textColor = .darkBlueText
      selectWordLabel.font = .regular(12)
    }
  }
  @IBOutlet var wordTextField: UITextField! {
    didSet {
      wordTextField.textColor = .lightBlueTint
      wordTextField.textAlignment = .center
      wordTextField.font = .medium(12)
    }
  }
  @IBOutlet var wordCountLabel: UILabel! {
    didSet {
      wordCountLabel.font = .regular(12)
      wordCountLabel.textColor = .darkGrayText
    }
  }
  @IBOutlet var wordButtonOne: PrimaryActionButton!
  @IBOutlet var wordButtonTwo: PrimaryActionButton!
  @IBOutlet var wordButtonThree: PrimaryActionButton!
  @IBOutlet var wordButtonFour: PrimaryActionButton!
  @IBOutlet var invalidWordButton: PrimaryActionButton!

  @IBOutlet var containerView: UIView!
  @IBOutlet var containerStackView: UIStackView!

  var coordinationDelegate: RestoreWalletViewControllerDelegate? {
    return generalCoordinationDelegate as? RestoreWalletViewControllerDelegate
  }

  lazy private var wordButtons: [PrimaryActionButton] = [wordButtonOne, wordButtonTwo, wordButtonThree, wordButtonFour]

  private var keypadToolbar: UIToolbar = {
    let keypadToolbar: UIToolbar = UIToolbar()
    keypadToolbar.backgroundColor = .lightGrayBackground
    let doneButton = UIBarButtonItem(title: "BACK TO PREVIOUS WORD", style: .done, target: self, action: #selector(previousWordButtonWasTouched))
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.medium(14),
      .foregroundColor: UIColor.lightBlueTint]
    doneButton.setTitleTextAttributes(attributes, for: .normal)
    let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

    keypadToolbar.items = [flexibleSpace, doneButton, flexibleSpace]
    keypadToolbar.sizeToFit()
    return keypadToolbar
  }()

  private var words: [String] = []

  override func accessibleViewsAndIdentifiers() -> [AccessibleViewElement] {
    return [
      (self.view, .restoreWallet(.page)),
      (wordTextField, .restoreWallet(.wordTextField))
    ]
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupNextWordEntry()
    invalidWordButton.style = .error
    wordTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    wordTextField.autocorrectionType = .no

    wordButtons.forEach { $0.addTarget(self, action: #selector(buttonWasPressed(_:)), for: .touchUpInside)}
    invalidWordButton.addTarget(self, action: #selector(invalidButtonWasTouched), for: .touchUpInside)
  }

  override func viewWillAppear(_ animated: Bool) {
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidAppear), name: UIResponder.keyboardDidShowNotification, object: nil)
  }

  @objc func keyboardDidAppear(_ notification: Notification) {
    setupConstraints(notification)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  private func setupConstraints(_ notification: Notification) {
    guard let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
    let keyboardRectangle = keyboardFrame.cgRectValue
    let keyboardHeight = keyboardRectangle.height
    let navigationBarHeight = navigationController?.toolbar.frame.size.height ?? 44

    //10 is UI spacing
    let height = UIScreen.main.bounds.height - keyboardHeight - UIApplication.shared.statusBarFrame.height - navigationBarHeight - 10

    guard height < containerView.frame.size.height else { return }

    containerStackView.spacing = 20
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.heightAnchor.constraint(equalToConstant: height).isActive = true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    wordTextField.becomeFirstResponder()
  }

  private func setupNextWordEntry() {
    hideAllWordButtons()
    invalidWordButton.disable()
    wordTextField.text = ""
    wordCountLabel.text = "word \(words.count + 1) of 12"
    wordCountLabel.isHidden = false
  }

  private func hideAllWordButtons() {
    wordButtons.forEach { $0.disable() }
  }

  private func hide(buttons: [PrimaryActionButton]) {
    buttons.forEach { $0.disable() }
  }

  private func setupInvalidState() {
    wordCountLabel.isHidden = true
    hideAllWordButtons()
    invalidWordButton.enable()
  }

  @objc func previousWordButtonWasTouched() {
    wordTextField.becomeFirstResponder()
    wordTextField.isUserInteractionEnabled = true
    wordTextField.text = words.removeLast()

    if words.count < 1 {
      wordTextField.inputAccessoryView = nil
      wordTextField.reloadInputViews()
    }

    textFieldDidChange(wordTextField)
  }

  @objc func invalidButtonWasTouched() {
    setupNextWordEntry()
  }

  @objc func buttonWasPressed(_ button: PrimaryActionButton) {
    guard let buttonText = button.titleLabel?.text else { return }
    guard words.count < 12 else {
      return
    }

    words.append(buttonText)

    if wordTextField.inputAccessoryView == nil {
      wordTextField.inputAccessoryView = keypadToolbar
      wordTextField.reloadInputViews()
    }

    if words.count == 12 {
      wordTextField.text = ""
      hideAllWordButtons()
      coordinationDelegate?.viewControllerDidSubmitWords(words: words)
    } else {
      setupNextWordEntry()
    }
  }

  @objc private func textFieldDidChange(_ textField: UITextField) {
    guard let searchText = textField.text, searchText.count > 1 else {
      hideAllWordButtons()
      return
    }

    let words: [String] = CNBHDWallet.allWords().filter { $0.starts(with: searchText) }

    if words.count > 4 {
      setupButtons(for: Array(words[0..<4]))
    } else if words.isEmpty {
      setupInvalidState()
    } else {
      setupButtons(for: words)
    }
  }

  private func setupButtons(for words: [String]) {
    guard !words.isEmpty else { return }
    wordCountLabel.isHidden = true
    invalidWordButton.disable()
    var buttonsToHide = wordButtons, index = 0
    for word in words {
      if let button = wordButtons[safe: index] {
        button.setTitle(word, for: .normal)
        wordButtons[index].enable()
        index += 1
      }
    }

    buttonsToHide.removeFirst(index)
    hide(buttons: buttonsToHide)
  }
}
