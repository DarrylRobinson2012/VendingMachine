//
//  VendingMachine.swift
//  VendingMachine
//
//  Created by Darryl Robinson  on 12/30/17.
//  Copyright © 2017 Treehouse Island, Inc. All rights reserved.
//

import Foundation
import UIKit
// Vending Machine items stored in a list

enum VendingSelection: String{
    case soda
    case dietSoda
    case chips
    case cookie
    case sandwich
    case wrap
    case candyBar
    case popTart
    case water
    case fruitJuice
    case sportsDrink
    case gum

    // Method to match the Vending machine item to an image
    
    func icon() -> UIImage {
        if let image = UIImage(named: self.rawValue){
            return image
        } else {
            return #imageLiteral(resourceName: "default")
    
    }
    
   /*       OR
     func icon() -> UIImage {
        if let image = UIImage(named: self.rawValue) {
            return image
        } else {
            return UIImage(named: "Default")!
        }
 */
    }

}


//The rules for the items

protocol VendingItem {
    var price: Double { get }
    var quantity: Int { get set }
}

// rules for the venidng Machine
protocol  VendingMachine {
    
    var selection: [VendingSelection] { get }
    var inventory: [VendingSelection: VendingItem] { get set }
    var amountDeposited: Double { get set }
    
    init(inventory: [VendingSelection: VendingItem])
    func vend(selection: VendingSelection, quantity: Int) throws //ex (5 cookies) is how itwill be shown
    func deposit(_ amount: Double)
    func item(forSelection selection: VendingSelection) -> VendingItem?
    
}
// THE actual Vending item

struct Item: VendingItem {
    let price: Double
    var quantity: Int
}

// The Errors the Plist Converter may face

enum InventoryError: Error {
    case invalidResource
    case conversionFailure
    case invalidSelection
}
// This converts a file into a dictionary
class PlistConverter {
    static func dictionary(fromFile name: String, ofType type: String) throws -> [String: AnyObject] {
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            throw InventoryError.invalidResource
        }
        guard let dictionary = NSDictionary(contentsOfFile: path) as? [String:AnyObject] else {
            throw InventoryError.conversionFailure
        }
        return dictionary
    }
}

// This takes in a dictionary and converts it to form that the vending Machine can accept.
class InventoryUnarchiver {
    static func vendingInventory(fromDictionary dictionary: [String: AnyObject]) throws -> [VendingSelection: VendingItem]{
        
        var inventory: [VendingSelection: VendingItem] = [:]
        
        for (key, value) in dictionary {
            if let itemDictionary = value as? [String: Any], let price = itemDictionary["price"] as? Double, let quantity = itemDictionary["quantity"] as? Int {
                let item = Item(price: price, quantity: quantity)
                
                guard let selection = VendingSelection(rawValue: key) else {
                    throw InventoryError.invalidSelection
                        }
                inventory.updateValue(item, forKey: selection)
            }
        }
        
        
        return inventory
    }
}
// Errors that the Vending Machine could face.
enum VendingMachineError: Error {
    case invalidSelection
    case outOfStock
    case insufficientFunds(required: Double)
}

// THE Actual Vending machine 
class foodVendingMachine: VendingMachine {
    let selection: [VendingSelection] = [.soda, .dietSoda,.chips,.cookie,.sandwich,.wrap,.candyBar,.popTart,.water,.fruitJuice,.sportsDrink,.gum]
    var inventory : [VendingSelection: VendingItem]
    var amountDeposited: Double = 10.0
    
    required init(inventory: [VendingSelection : VendingItem]) {
        self.inventory = inventory
    }
        //vend items
    func vend(selection: VendingSelection, quantity: Int) throws {
        guard var item = inventory[selection] else {
            throw VendingMachineError.invalidSelection
        }
        guard item.quantity >= quantity else {
            throw VendingMachineError.outOfStock
        }
    
        let totalPrice = item.price * Double(quantity)
        if amountDeposited >= totalPrice {
            amountDeposited -= totalPrice
            
            item.quantity -= quantity
            
            inventory.updateValue(item, forKey: selection)
        } else {
            let amountRequired = totalPrice - amountDeposited
            throw VendingMachineError.insufficientFunds(required: amountRequired)
        }
    }
    // deposit amount
    func deposit(_ amount: Double) {
        amountDeposited += amount
    }
    // returnin the actual item name 
    func item(forSelection selection: VendingSelection) -> VendingItem? {
        return inventory[selection]
    }
    
    
}
