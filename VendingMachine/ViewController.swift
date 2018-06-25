//
//  ViewController.swift
//  VendingMachine
//
//  Created by Darryl Robinson on 12/1/16.
//  Copyright © 2016 Treehouse Island, Inc. All rights reserved.
//

import UIKit

fileprivate let reuseIdentifier = "vendingItem"
fileprivate let screenWidth = UIScreen.main.bounds.width

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var quantityStepper: UIStepper!
    
    // calling on vendingmachine
    
    let vendingMachine: VendingMachine
    var currentSelection: VendingSelection?
    
    // ??
    required init?(coder aDecoder: NSCoder) {
        // do clause to run the converter , unarchvier, and polulating the vending Machine.
        do {
            let dictionary = try PlistConverter.dictionary(fromFile: "VendingInventory", ofType: "plist")
            let inventory = try InventoryUnarchiver.vendingInventory(fromDictionary: dictionary)
            self.vendingMachine = foodVendingMachine(inventory: inventory)
        } catch let error {
            fatalError("\(error)")
        }
        //?
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupCollectionViewCells()
        
    
        updateDisplaywith(balance: vendingMachine.amountDeposited, totalprice: 0.0, itemPrice: 0.0, itemQuantity: 1)
    
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Setup

    func setupCollectionViewCells() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        
        let padding: CGFloat = 10
        let itemWidth = screenWidth/3 - padding
        let itemHeight = screenWidth/3 - padding
        
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        collectionView.collectionViewLayout = layout
    }
    
    
    //MARK: -  Vending Machine
    // Purchase the items
    
    @IBAction func purchase() {
        if let currentSelection = currentSelection {
            do {
            // this do catch file runs vend function and update the values on display while catching the errors associted with vendingMachine 
                
               try vendingMachine.vend(selection: currentSelection, quantity: Int(quantityStepper.value))
                updateDisplaywith(balance: vendingMachine.amountDeposited, totalprice: 0.0, itemPrice: 0.0, itemQuantity: 1)
                
            } catch VendingMachineError.outOfStock {
                showAlertWith(title: "Out of Stock", message: "This item is unavailable. Please make another selection")
               
            } catch VendingMachineError.insufficientFunds(let required) {
               let message = " You need $\(required) to complete the transactioin"
                showAlertWith(title: "Insufficient Funds", message: message)
            } catch VendingMachineError.invalidSelection {
                showAlertWith(title: "Invalid Selection", message: "Please make another selection")
            } catch let error{
            fatalError("\(error)")
            
            }
            if let indexPath = collectionView.indexPathsForSelectedItems?.first{
                collectionView.deselectItem(at: indexPath, animated: true)
                updateCell(having: indexPath, selected: false)
            }
        
        } else {
            // FIXME: Alert user to no selection
        }
    
    }
    // update the values on the main display
    func updateDisplaywith(balance:  Double? = nil, totalprice: Double? = nil, itemPrice: Double? = nil, itemQuantity: Int? = nil) {
        if let balanceValue = balance {
            balanceLabel.text = "$\(vendingMachine.amountDeposited)"
        
        }
        if let totalValue = totalprice {
            totalLabel.text = "$\(totalValue)"
        }
        
        if let priceValue = itemPrice{
        priceLabel.text = "$\(priceValue)"
        }
        
        if let quantityValue = itemQuantity {
            quantityLabel.text = "\(quantityValue)"
        }
    }
    
    // update total price
    
    func updateTotalPrice(for item: VendingItem) {
        let totalPrice = item.price * quantityStepper.value
        updateDisplaywith(itemPrice: totalPrice)
    }
    
    // update total Quantity
    
    @IBAction func updateQuantity(_ sender: UIStepper) {
        let quantity = Int(quantityStepper.value)
        updateDisplaywith(itemQuantity: quantity)
       
        if let currentSelection = currentSelection, let item = vendingMachine.item(forSelection: currentSelection){
            updateTotalPrice(for: item)
        }
    }
    
    // This function displays an Alert Dialogue Box
    
    func showAlertWith(title: String, message: String, style: UIAlertControllerStyle = .alert) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        
        present(alertController, animated: true, completion: nil)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: dismissAlert)
        alertController.addAction(okAction)
    }
    
    // This function gets rid of the alert
    func dismissAlert(sender: UIAlertAction) -> Void {
        updateDisplaywith(balance: 0, totalprice: 0, itemPrice: 0, itemQuantity: 1)
        
    }
    
    //This function adds funds
    @IBAction func depositFunds() {
        vendingMachine.deposit(5.0)
        updateDisplaywith(balance: vendingMachine.amountDeposited)
    }
    
    
    // MARK: UICollectionViewDataSource
    //??
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vendingMachine.selection.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? VendingItemCell else { fatalError() }
        // display icon
        let item = vendingMachine.selection[indexPath.row]
        cell.iconView.image = item.icon()
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: true)
      
        
        quantityStepper.value = 1
      
        updateDisplaywith( totalprice: 0.0,itemQuantity: 1)
        
        currentSelection = vendingMachine.selection[indexPath.row]
        
        // update price
        if let currentSelection = currentSelection, let item = vendingMachine.item(forSelection: currentSelection ) {
            
            let totalPrice = item.price * quantityStepper.value
            
            updateDisplaywith(totalprice: totalPrice, itemPrice: item.price)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: false)
    
    
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: false)
    }
    
    func updateCell(having indexPath: IndexPath, selected: Bool) {
        
        let selectedBackgroundColor = UIColor(red: 41/255.0, green: 211/255.0, blue: 241/255.0, alpha: 1.0)
        let defaultBackgroundColor = UIColor(red: 27/255.0, green: 32/255.0, blue: 36/255.0, alpha: 1.0)
        
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.backgroundColor = selected ? selectedBackgroundColor : defaultBackgroundColor
        }
    }
    
    
}

