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

  func fetchImage(at urlString: String, completion: @escaping (Data) -> Void) {
    guard let url = URL(string: urlString) else { return }
    _dataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, _, _) in
      guard let data = data, let image = UIImage(data: data) else { return }
      DispatchQueue.main.async {
        self?.thumbnailImageView.image = image
        completion(data)
      }
    }
  }

  var source: NewsArticleResponse.Source?
  var sourceImage: UIImage? {
    guard let localSource = source else { return nil }
    switch localSource {
    case .ccn: return UIImage(imageLiteralResourceName: "ccnIcon")
    case .ambcrypto: return UIImage(imageLiteralResourceName: "ambcryptoIcon")
    case .reddit: return UIImage(imageLiteralResourceName: "redditIcon")
    case .coindesk: return UIImage(imageLiteralResourceName: "coindeskIcon")
    case .cointelegraph: return UIImage(imageLiteralResourceName: "cointelegraphIcon")
    case .coinninja: return UIImage(imageLiteralResourceName: "coinninjaIcon")
    case .coinsquare: return UIImage(imageLiteralResourceName: "coinsquareIcon")
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
      sourceLabel.font = .regular(11)
      sourceLabel.textColor = .darkGrayText
    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    selectionStyle = .none
    backgroundColor = .lightGrayBackground
  }

  func load(article: NewsArticleResponse,
            imageFetcher: @escaping (Data) -> Void) {
    titleLabel.text = article.title
    sourceLabel.text = article.getFullSource()
    self.source = article.source.flatMap { NewsArticleResponse.Source(rawValue: $0) }
    if let image = sourceImage {
      thumbnailImageView.image = image
    } else if let data = article.imageData, let image = UIImage(data: data) {
      thumbnailImageView.image = image
    } else {
      let urlString = article.thumbnail ?? NewsArticleResponse.Source.coinninja.rawValue
      fetchImage(at: urlString, completion: imageFetcher)
    }
  }
}
