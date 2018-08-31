//
//  ProductsTableViewController.swift
//  HuTieu883
//
//  Created by Thinh Le on 2018-08-31.
//  Copyright © 2018 Thinh Le. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

class ProductsTableViewController: UITableViewController {
    
    let PRODUCT_URL = "https://www.thinhmle.com/api/ProductList_2_skintree.json"
    let params : [String : String] = ["userId" : "userId", "password" : "password"]
    var products: Array = [ProductModel]()

    override func viewDidLoad() {
        super.viewDidLoad()

        getProductData(url: PRODUCT_URL, parameters: params)
    }

    // MARK: - Networking
    func getProductData(url: String, parameters: [String: String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                let productJSON : JSON = JSON(response.result.value!)
                self.obtainProductData(json: productJSON)
                self.tableView.reloadData()
            } else {
                print("Error \(String(describing: response.result.error))")
            }
        }
    }
    
    // MARK: - JSON Parsing
    func obtainProductData(json: JSON) {
        let productList = json["products"]
        
        for product in productList {
            let productModel = ProductModel()
            productModel.name = product.1["name"].stringValue
            productModel.thumbnailURL = product.1["thumbnailUrl"].stringValue
            products.append(productModel)
        }
        
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath)

        let prod = products[indexPath.row]
        cell.textLabel?.text = prod.name
        cell.detailTextLabel?.text = prod.thumbnailURL
        
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
