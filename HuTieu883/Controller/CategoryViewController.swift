//
//  CategoryViewController.swift
//  HuTieu883
//
//  Created by Thinh Le on 9/19/18.
//  Copyright © 2018 Thinh Le. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreData

//@available(iOS 10.0, *)
class CategoryViewController: UITableViewController {
    
    let PRODUCT_URL = "https://www.thinhmle.com/api/ProductList_skintree.json"
    let params : [String : String] = ["userId" : "userId", "password" : "password"]
    
    var categories: Array = [Category]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let request: NSFetchRequest<Category> = Category.fetchRequest()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "List of Categories"
        
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        
        getCategoriesFrom(url: PRODUCT_URL, parameters: params)

    }
    
    func getCategoriesFrom(url: String, parameters: [String: String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                let productJSON : JSON = JSON(response.result.value!)
                self.obtainCategoriesByDecoding(json: productJSON)
                self.tableView.reloadData()
            } else {
                print("Error connecting to the internet \(String(describing: response.result.error))")
            }
        }
    }
    
    // MARK: - JSON Parsing
    func obtainCategoriesByDecoding(json: JSON) {
        self.deleteCategoriesFromCoreData()
        
        categories.removeAll()
        for (key, _) in json {
            let category = Category(context: self.context)
            category.name = key
            categories.append(category)
        }
    
        self.saveCategoriesToCoreData()
        self.loadCategoriesFromCoreData()
    }

    // MARK: - TableView datasource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)

        let cat:Category = categories[indexPath.row]

        cell.textLabel?.text = cat.name!

        return cell
    }
    
    // MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowProductsTableVC", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let productsTableVC = segue.destination as! ProductsTableViewController
        
        if let indexPath = tableView.indexPathForSelectedRow {
            productsTableVC.categorySelected = categories[indexPath.row]
        }
        
    }
    
    // MARK: - Data Manipulation Methods
    func saveCategoriesToCoreData() {
        
        do {
            try context.save()
        } catch {
            print("Error saving context \(error)")
        }
    }
    
    func loadCategoriesFromCoreData(with request: NSFetchRequest<Category> = Category.fetchRequest()) {
        
        do {
            categories = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
        
        self.tableView.reloadData()
    }
    
    func deleteCategoriesFromCoreData() {

        do {
            categories = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }

        if categories.count > 0 {
            for i in 0..<categories.count {
                context.delete(categories[i])
            }
        }
        self.saveCategoriesToCoreData()
    }

}
