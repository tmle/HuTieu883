//
//  DetailedProductViewController.swift
//  HuTieu883
//
//  Created by Thinh Le on 2018-08-31.
//  Copyright © 2018 Thinh Le. All rights reserved.
//

import UIKit

class DetailedProductViewController: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var descTextView: UITextView!
    
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    
    var productSelected: ProductModel? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.nameLabel.textColor = .darkBlueColor
        self.nameLabel.text = productSelected?.name
        
        self.descTextView.textColor = .darkBlueColor
        self.descTextView.text = productSelected?.desc
        self.thumbnailImageView.image = productSelected?.thumbnail
        
        self.currencyLabel.text = productSelected?.currency
        self.priceLabel.text = productSelected?.price        
        self.unitLabel.text = productSelected?.unit
        self.weightLabel.text = productSelected?.weight
        
    }

}
