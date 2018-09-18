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
    var thumbnailURL: String = ""
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
    //1
    let productModel: ProductModel
    
    //2
    init(productModel: ProductModel) {
        self.productModel = productModel
    }
    
    //3
    override func main() {
        //4
        if self.isCancelled {
            return
        }
        //5
        let currentUrl = URL(string: productModel.thumbnailURL)!
        let imageData = try? Data(contentsOf: currentUrl)
        
        //6
        if self.isCancelled {
            return
        }
        
        //7
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


