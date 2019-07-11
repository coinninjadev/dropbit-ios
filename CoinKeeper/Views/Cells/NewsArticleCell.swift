//
//  NewsArticleCell.swift
//  DropBit
//
//  Created by Mitchell Malleo on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class NewsArticleCell: UITableViewCell {

  override func prepareForReuse() {
    source = nil
    thumbnailImageView.image = nil
    _dataTask = nil
    setNeedsDisplay()
  }

  private var _dataTask: URLSessionDataTask? {
    didSet {
      _dataTask?.resume()
    }
  }

  private lazy var imageCompletion: (Data?, URLResponse?, Error?) -> Void = { [weak self] data, response, error in
    guard let data = data else { return }
    DispatchQueue.main.async {
      self?.thumbnailImageView.image = UIImage(data: data)
    }
  }

  var imageURL: String = "" {
    didSet {
      guard let url = URL(string: imageURL) else { return }
      _dataTask = URLSession.shared.dataTask(with: url, completionHandler: imageCompletion)
    }
  }

  var source: NewsArticleResponse.Source? {
    didSet {
      _dataTask?.suspend()
      switch source {
      case .ccn?:
        thumbnailImageView.image = #imageLiteral(resourceName: "ccnIcon")
      case .ambcrypto?:
        thumbnailImageView.image = #imageLiteral(resourceName: "ambcryptoIcon")
      case .reddit?:
        thumbnailImageView.image = #imageLiteral(resourceName: "redditIcon")
      case .coindesk?:
        thumbnailImageView.image = #imageLiteral(resourceName: "coindeskIcon")
      case .cointelegraph?:
        thumbnailImageView.image = #imageLiteral(resourceName: "cointelegraphIcon")
      case .coinninja?:
        thumbnailImageView.image = #imageLiteral(resourceName: "coinninjaIcon")
      case .coinsquare?:
        thumbnailImageView.image = #imageLiteral(resourceName: "coinsquareIcon")
      default:
        thumbnailImageView.image = nil
      }
    }
  }

  @IBOutlet var thumbnailImageView: UIImageView! {
    didSet {
      thumbnailImageView.contentMode = .scaleAspectFill
      thumbnailImageView.layer.cornerRadius = 10.0
      thumbnailImageView.clipsToBounds = true
    }
  }

  @IBOutlet var titleLabel: UILabel! {
    didSet {
      titleLabel.font = .medium(14)
    }
  }

  @IBOutlet var sourceLabel: UILabel! {
    didSet {
      sourceLabel.font = .regular(10)
      sourceLabel.textColor = .lightGrayText
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    selectionStyle = .none
    backgroundColor = .lightGrayBackground
  }
}
