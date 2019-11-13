//
//  NewsArticleCell.swift
//  DropBit
//
//  Created by Mitchell Malleo on 6/19/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

class NewsArticleCell: UITableViewCell, FetchImageType {

  override func prepareForReuse() {
    source = nil
    thumbnailImageView.image = nil
    dataTask = nil
    setNeedsDisplay()
  }

  var dataTask: URLSessionDataTask? {
    didSet {
      dataTask?.resume()
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
    case .theblock: return UIImage(imageLiteralResourceName: "theBlockIcon")
    case .bitcoinmagazine: return UIImage(imageLiteralResourceName: "bitcoinMagazineIcon")
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
            imageFetcher: @escaping (UIImage) -> Void) {
    titleLabel.text = article.title
    sourceLabel.text = article.getFullSource()
    self.source = article.source.flatMap { NewsArticleResponse.Source(rawValue: $0) }
    if let image = sourceImage {
      thumbnailImageView.image = image
    } else if let image = article.image {
      thumbnailImageView.image = image
    } else {
      let urlString = article.thumbnail ?? NewsArticleResponse.Source.coinninja.rawValue
      fetchImage(at: urlString, completion: imageFetcher)
    }
  }
}
