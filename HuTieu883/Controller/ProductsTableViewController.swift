//
//  ProductsTableViewController.swift
//  HuTieu883
//
//  Created by Thinh Le on 2018-08-31.
//  Copyright © 2018 Thinh Le. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreData

class ProductsTableViewController: UITableViewController {
    let pendingOperations = PendingOperations()
    let start = DispatchTime.now()
    
    let PRODUCT_URL = "https://www.thinhmle.com/api/ProductList_skintree.json"
    let params : [String : String] = ["userId" : "userId", "password" : "password"]
    
    var products: Array = [ProductModel]() //data copied from Core Data
    var productSelected: ProductModel?
    var categorySelected: Category? {
        didSet {
            if (self.categorySelected!.name == "skincare") {
                title = "Skin Care Products"
            } else {
                title = "Supplements"
            }
            
            loadProductsFromCoreData()

        }
        
    }
    
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var productDataArray: Array = [ProductData]()
    let request: NSFetchRequest<ProductData> = ProductData.fetchRequest()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))

        getProductDataFrom(url: PRODUCT_URL, parameters: params)
        
    }
    
    // MARK: - Networking
    func getProductDataFrom(url: String, parameters: [String: String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                let productJSON : JSON = JSON(response.result.value!)
                self.obtainProductDataByDecoding(json: productJSON)
            } else {
                print("Error connecting to the internet \(String(describing: response.result.error))")
            }
        }
    }
    
    // MARK: - JSON Parsing
    func obtainProductDataByDecoding(json: JSON) {
        let productList = json[self.categorySelected!.name!]
        
        self.deleteProductsFromCoreData()
        productDataArray.removeAll()
        for product in productList {
            let productData = ProductData(context: self.context)
            productData.name = product.1["name"].stringValue
            productData.brief = product.1["brief"].stringValue
            productData.desc = product.1["description"].stringValue
            productData.thumbnailURL = product.1["thumbnailUrl"].stringValue
            productData.currency = product.1["currency"].stringValue
            productData.price = product.1["price"].stringValue
            productData.unit = product.1["unit"].stringValue
            productData.weight = product.1["weight"].stringValue
            productData.parentCategory = self.categorySelected
            
            productDataArray.append(productData)
        }
        
        self.saveProductsToCoreData()
        self.loadProductsFromCoreData()

    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductCell", for: indexPath)

        if cell.accessoryView == nil {
            let indicator = UIActivityIndicatorView(style: .gray)
            cell.accessoryView = indicator
        }
        let indicator = cell.accessoryView as! UIActivityIndicatorView
        
        let myView = UIView()
        if (self.categorySelected!.name == "skincare") {
            if (indexPath.row % 2 == 0) {
                myView.backgroundColor = UIColor(red: 0.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
            } else {
                myView.backgroundColor = UIColor(red: 0.0/255.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1.0)
            }
        } else {
            if (indexPath.row % 2 == 0) {
                myView.backgroundColor = UIColor(red: 120.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
            } else {
                myView.backgroundColor = UIColor(red: 150.0, green: 230.0/255.0, blue: 230.0/255.0, alpha: 1.0)
            }
            
        }
        
        cell.backgroundView = myView;
        
        let prod:ProductModel = products[indexPath.row]
        
        switch (prod.state) {
        case .failed:
            indicator.stopAnimating()
            cell.textLabel?.text = "failed to load"
            cell.textLabel!.textColor = UIColor.black
            cell.detailTextLabel?.text = "..."
            cell.detailTextLabel!.textColor = UIColor.black
            cell.imageView?.image = UIImage(named: "not-avail-48x48.png")
            
        case .downloaded:
            indicator.stopAnimating()
            cell.textLabel!.font = UIFont.systemFont(ofSize: 17.0)
            cell.textLabel!.textColor = UIColor(red: 0.0, green: 0.004, blue: 0.502, alpha: 1.0)
            cell.textLabel?.text = prod.name
            cell.detailTextLabel!.font = UIFont.systemFont(ofSize: 15.0)
            cell.detailTextLabel!.textColor = UIColor(red: 0.5, green: 0.004, blue: 0.502, alpha: 1.0)
            cell.detailTextLabel?.text = prod.brief
            cell.imageView?.image = prod.thumbnail

        case .new:
            indicator.startAnimating()
            cell.imageView?.image = UIImage(named: "camera-48x48.png")
            cell.textLabel!.font = UIFont.systemFont(ofSize: 17.0)
            cell.textLabel!.textColor = UIColor(red: 0.0, green: 0.004, blue: 0.502, alpha: 1.0)
            cell.textLabel?.text = "downloading ... "
            cell.detailTextLabel!.font = UIFont.systemFont(ofSize: 15.0)
            cell.detailTextLabel!.textColor = UIColor(red: 0.5, green: 0.004, blue: 0.502, alpha: 1.0)
            cell.detailTextLabel?.text = "..."
            
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
            let end = DispatchTime.now()
            
            let nanoTime = end.uptimeNanoseconds - self.start.uptimeNanoseconds
            let timeInterval = Double(nanoTime) / 1_000_000_000
            print("Time to get first photo: \(timeInterval) seconds")
            
        default:
            let _: String = ""
        }
    }
    
    func startDownloadForProduct(_ product: ProductModel, indexPath: IndexPath){
        if pendingOperations.downloadsInProgress[indexPath] != nil {
            return
        }
        
        let downloader = ImageDownloader(productModel: product)

        downloader.completionBlock = {
            if downloader.isCancelled {
                return
            }
            DispatchQueue.main.async(execute: {
                self.pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            })
        }
        pendingOperations.downloadsInProgress[indexPath] = downloader

        pendingOperations.downloadQueue.addOperation(downloader)
    }
    
    // MARK: - Table Cell Operations
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        suspendAllOperations()
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            loadImagesForOnscreenCells()
            resumeAllOperations()
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
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
        if let pathsArray = tableView.indexPathsForVisibleRows {
            let allPendingOperations = Set(Array(pendingOperations.downloadsInProgress.keys))
            
            var toBeCancelled = allPendingOperations
            let visiblePaths = Set(pathsArray )
            toBeCancelled.subtract(visiblePaths)
            
            var toBeStarted = visiblePaths
            toBeStarted.subtract(allPendingOperations)
            
            for indexPath in toBeCancelled {
                if let pendingDownload = pendingOperations.downloadsInProgress[indexPath] {
                    pendingDownload.cancel()
                }
                pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
            }
            
            for indexPath in toBeStarted {
                let indexPath = indexPath as IndexPath
                let productToProcess = self.products[(indexPath as NSIndexPath).row]
                startOperationsForProductModel(productToProcess, indexPath: indexPath)
            }
        }
    }
    
    // MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.cellForRow(at: indexPath)?.accessoryType = tableView.cellForRow(at: indexPath)?.accessoryType == .checkmark ? .none : .checkmark
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.productSelected = self.products[indexPath.row]
        performSegue(withIdentifier: "ShowDetailVC", sender: self)
    }
    
    // MARK: - Refresh button
    @IBAction func refreshButtonPressed(_ sender: UIBarButtonItem) {
        productDataArray.removeAll()
        getProductDataFrom(url: PRODUCT_URL, parameters: params)
    }
    
    // MARK: - Data Manipulation Methods
    func saveProductsToCoreData() {
        
        do {
            try context.save()
        } catch {
            print("Error saving context \(error)")
        }
    }
    
    func loadProductsFromCoreData(with request: NSFetchRequest<ProductData> = ProductData.fetchRequest(), predicate: NSPredicate? = nil) {
        
        print(categorySelected!.name!)
        let categoryPredicate = NSPredicate(format: "parentCategory.name CONTAINS[cd] %@", categorySelected!.name!)
        
        if let additionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
        } else {
            request.predicate = categoryPredicate
        }
        
        do {
           productDataArray = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
        
        products.removeAll()
        for productData in productDataArray {
            let productModel = ProductModel()
            productModel.name = productData.name!
            productModel.brief = productData.brief!
            productModel.desc = productData.desc!
            productModel.thumbnailURL = productData.thumbnailURL!
            productModel.currency = productData.currency!
            productModel.price = productData.price!
            productModel.unit = productData.unit!
            productModel.weight = productData.weight!
            products.append(productModel)
        }
        
        self.tableView.reloadData()
    }
    
    func deleteProductsFromCoreData() {

        do {
            productDataArray = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
        
        if productDataArray.count > 0 {
            for i in 0..<productDataArray.count {
                context.delete(productDataArray[i])
            }
        }
        
        self.saveProductsToCoreData()
        
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "ShowDetailVC") {
            if let detailedProductViewController = segue.destination as? DetailedProductViewController {
                detailedProductViewController.productSelected = self.productSelected
            }
        }
    }

}

// MARK: - Search Bar methods
extension ProductsTableViewController : UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let request: NSFetchRequest<ProductData> = ProductData.fetchRequest()
        
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", searchBar.text!)
        
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        loadProductsFromCoreData(with: request)
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadProductsFromCoreData(with: request)
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
    
}
