//
//  FetchImageType.swift
//  DropBit
//
//  Created by Mitchell Malleo on 11/12/19.
//  Copyright © 2019 Coin Ninja, LLC. All rights reserved.
//

import Foundation
import UIKit

protocol FetchImageType: AnyObject {
  var dataTask: URLSessionDataTask? { get set }
}

extension FetchImageType {

  func fetchImage(at urlString: String, completion: @escaping (UIImage) -> Void) {
    guard let url = URL(string: urlString) else { return }
    dataTask = URLSession.shared.dataTask(with: url) { (data, _, _) in
      guard let data = data, let image = UIImage(data: data) else { return }
      DispatchQueue.main.async {
        completion(image)
      }
    }
  }
}
