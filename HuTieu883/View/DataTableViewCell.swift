//
//  DataTableViewCell.swift
//  HuTieu883
//
//  Created by Thinh Le on 2018-09-03.
//  Copyright © 2018 Thinh Le. All rights reserved.
//

import UIKit

class DataTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    func configureCell(_ text: String) {
        titleLabel.text = text
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
