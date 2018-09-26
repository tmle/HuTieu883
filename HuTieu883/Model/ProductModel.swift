//
//  ProductModel.swift
//  HuTieu883
//
//  Created by Thinh Le on 2018-08-31.
//  Copyright © 2018 Thinh Le. All rights reserved.
//

import Foundation
import UIKit

enum ProductModelState {
    case new, downloaded, failed
}


class ProductModel {
    var name: String = ""
    var brief: String = ""
    var desc: String = ""
    var thumbnailURL: String = ""
    var currency: String = ""
    var price: String = ""
    var unit: String = ""
    var weight: String = ""
    var state = ProductModelState.new
    var thumbnail = UIImage(named: "camera-48x48.png")
    
    init() {
    }

    func hasThumbnail(productThumbnailURL: String) -> Bool {
        return (productThumbnailURL != "") ? true : false
    }

}

class PendingOperations {
    lazy var downloadsInProgress = [IndexPath:Operation]()
    lazy var downloadQueue:OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
}

class ImageDownloader: Operation {
    let productModel: ProductModel
    
    init(productModel: ProductModel) {
        self.productModel = productModel
    }
    
    override func main() {
        if self.isCancelled {
            return
        }
        let currentUrl = URL(string: productModel.thumbnailURL)!
        let imageData = try? Data(contentsOf: currentUrl)
        
        if self.isCancelled {
            return
        }
        
        if imageData != nil {
            self.productModel.thumbnail = UIImage(data:imageData!)
            self.productModel.state = .downloaded
        }
        else
        {
            self.productModel.state = .failed
            self.productModel.thumbnail = UIImage(named: "not-avail-48x48.png")
        }
    }
}


