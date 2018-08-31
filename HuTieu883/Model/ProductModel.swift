//
//  ProductModel.swift
//  HuTieu883
//
//  Created by Thinh Le on 2018-08-31.
//  Copyright © 2018 Thinh Le. All rights reserved.
//

import Foundation

class ProductModel {
    var name: String = ""
    var brief: String = ""
    var thumbnailURL: String = "";
    
    init() {
        
    }

    func hasThumbnail(productThumbnailURL: String) -> Bool {
        return (productThumbnailURL != "") ? true : false
    }

}
