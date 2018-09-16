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
    let pendingOperations = PendingOperations()
    let start = DispatchTime.now() // <<<<<<<<<< Start time
    
    let PRODUCT_URL = "https://www.thinhmle.com/api/ProductList_2_skintree.json"
    let params : [String : String] = ["userId" : "userId", "password" : "password"]
    
    var products: Array = [ProductModel]()
    var filteredProducts: Array = [ProductModel]()
    
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "List of Products"

        getProductDataFrom(url: PRODUCT_URL, parameters: params)
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Products"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
    }
    
    // MARK: - Networking
    func getProductDataFrom(url: String, parameters: [String: String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                let productJSON : JSON = JSON(response.result.value!)
                self.obtainProductDataByDecoding(json: productJSON)
                self.tableView.reloadData()
            } else {
                print("Error \(String(describing: response.result.error))")
            }
        }
    }
    
    // MARK: - JSON Parsing
    func obtainProductDataByDecoding(json: JSON) {
        let productList = json["products"]
        
        for product in productList {
            let productModel = ProductModel()
            productModel.name = product.1["name"].stringValue
            productModel.brief = product.1["brief"].stringValue
            productModel.thumbnailURL = product.1["thumbnailUrl"].stringValue
            products.append(productModel)
        }
        
    }
    
    // MARK: - Private instance methods
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredProducts = products.filter({ (product: ProductModel) -> Bool in
            return product.name.lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredProducts.count
        }
        
        return products.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath)

        
        //1
        if cell.accessoryView == nil {
            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            cell.accessoryView = indicator
        }
        let indicator = cell.accessoryView as! UIActivityIndicatorView
        
        
        //2
        let prod: ProductModel
        
        if isFiltering() {
            prod = filteredProducts[indexPath.row]
        } else {
            prod = products[indexPath.row]
        }
        
        //3
        cell.imageView?.image = prod.thumbnail
        
        //4
        switch (prod.state) {
        case .failed:
            indicator.stopAnimating()
            cell.textLabel?.text = "Failed to load"
        case .downloaded:
            indicator.stopAnimating()
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            cell.textLabel!.font = UIFont.systemFont(ofSize: 17.0)
            cell.textLabel!.textColor = UIColor(red: 0.0, green: 0.004, blue: 0.502, alpha: 1.0)
            cell.textLabel?.text = prod.name
            cell.detailTextLabel!.font = UIFont.systemFont(ofSize: 15.0)
            cell.detailTextLabel!.textColor = UIColor(red: 0.5, green: 0.004, blue: 0.502, alpha: 1.0)
            cell.detailTextLabel?.text = prod.brief
        case .new:
            indicator.startAnimating()
            if (!tableView.isDragging && !tableView.isDecelerating) {
                self.startOperationsForProductModel(prod, indexPath: indexPath)
            }
        }

        return cell
    }
    
    // MARK: - Asynchronous Image Downloading
    func startOperationsForProductModel(_ product: ProductModel, indexPath: IndexPath){
        switch (product.state) {
        case .new:
            startDownloadForProduct(product, indexPath: indexPath)
            
        case .downloaded:
            let end = DispatchTime.now()   // <<<<<<<<<<   end time
            
            //    let theAnswer = self.checkAnswer(answerNum: "\(problemNumber)", guess: myGuess)
            let nanoTime = end.uptimeNanoseconds - self.start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
            let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests
            
            print("Time to get first photo: \(timeInterval) seconds")
            
        default:
            let _: String = ""
        }
    }
    
    func startDownloadForProduct(_ product: ProductModel, indexPath: IndexPath){
        //1
        if pendingOperations.downloadsInProgress[indexPath] != nil {
            return
        }
        
        //2
        let downloader = ImageDownloader(productModel: product)
        //3
        downloader.completionBlock = {
            if downloader.isCancelled {
                return
            }
            DispatchQueue.main.async(execute: {
                self.pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            })
        }
        //4
        pendingOperations.downloadsInProgress[indexPath] = downloader
        //5
        pendingOperations.downloadQueue.addOperation(downloader)
    }
    
    // MARK: - Table Cell Operations
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //1
        suspendAllOperations()
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // 2
        if !decelerate {
            loadImagesForOnscreenCells()
            resumeAllOperations()
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 3
        loadImagesForOnscreenCells()
        resumeAllOperations()
    }
    
    func suspendAllOperations () {
        pendingOperations.downloadQueue.isSuspended = true
    }
    
    func resumeAllOperations () {
        pendingOperations.downloadQueue.isSuspended = false
    }
    
    func loadImagesForOnscreenCells () {
        //1
        if let pathsArray = tableView.indexPathsForVisibleRows {
            //2
            let allPendingOperations = Set(Array(pendingOperations.downloadsInProgress.keys))
            
            //3
            var toBeCancelled = allPendingOperations
            let visiblePaths = Set(pathsArray )
            toBeCancelled.subtract(visiblePaths)
            
            //4
            var toBeStarted = visiblePaths
            toBeStarted.subtract(allPendingOperations)
            
            // 5
            for indexPath in toBeCancelled {
                if let pendingDownload = pendingOperations.downloadsInProgress[indexPath] {
                    pendingDownload.cancel()
                }
                pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
            }
            
            // 6
            for indexPath in toBeStarted {
                let indexPath = indexPath as IndexPath
                let productToProcess = self.products[(indexPath as NSIndexPath).row]
                startOperationsForProductModel(productToProcess, indexPath: indexPath)
            }
        }
    }
    
    // MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        
        tableView.cellForRow(at: indexPath)?.accessoryType = tableView.cellForRow(at: indexPath)?.accessoryType == .checkmark ? .none : .checkmark
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Refresh button

    @IBAction func refreshButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Update coredata", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add item", style: .default) { (action) in
            //
            let prod = ProductModel()
            prod.name = textField.text!
            prod.brief = "So inconvenient"
            prod.thumbnailURL = "https://thinhmle.com/eCommerce/images/skintree/SM-RednessReliefCalmPlex.jpg"
            
            self.products.append(prod)
            
            self.tableView.reloadData()
            
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }
        
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
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

// MARK: - Search Bar methods

extension ProductsTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

// This method is used for iOS 9.3, with a UISearchBar placed in the storyboard.
//extension ProductsTableViewController : UISearchBarDelegate {
//
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        filteredProductNames = searchText.isEmpty ? originProductNames : originProductNames.filter({(dataString: String) -> Bool in
//            return dataString.range(of: searchText, options: .caseInsensitive) != nil
//        })
//        tableView.reloadData()
//    }
//
//}
