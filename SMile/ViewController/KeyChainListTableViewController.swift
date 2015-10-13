//
//  KeyChainListTableViewController.swift
//  FixMyMail
//
//  Created by Sebastian Thürauf on 16.05.15.
//  Copyright (c) 2015 FixMymail. All rights reserved.
//

import UIKit
import CoreData
import Foundation

class KeyChainListTableViewController: UITableViewController {
	
	weak var delegate: ContentViewControllerProtocol?
	weak var receivedFileDelegate: ReceivedFileViewControllerProtocol?
	var keyDetailVC: KeyDetailTableViewController?
	var keysFromCoreData = [Key]()
	var managedObjectContext: NSManagedObjectContext?
	var myGrayColer = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
	let myOpacity: CGFloat = 0.1
	let myOpacityFULL: CGFloat = 1.0
	let monthsInYear: Int = 12
	let monthsForFullValidity: Int = 6
	
	var isInKeySelectionMode: Bool = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//Load some KeyItems
		loadInitialData()
		
		
		tableView.registerNib(UINib(nibName: "KeyItemTableViewCell", bundle: nil),forCellReuseIdentifier:"ListPrototypCell")
		
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		//self.navigationItem.rightBarButtonItem = self.editButtonItem()
		if self.isInKeySelectionMode {
			self.navigationItem.title = "Select a Key"
			let cancelItem: UIBarButtonItem = UIBarButtonItem(title: "  Cancel", style: .Plain, target: self, action: "cancelTapped:")
			self.navigationItem.leftBarButtonItem = cancelItem
		} else {
		let menuItem: UIBarButtonItem = UIBarButtonItem(title: "  Menu", style: .Plain, target: self, action: "menuTapped:")
		self.navigationItem.title = "KeyChain"
		self.navigationItem.leftBarButtonItem = menuItem
		self.navigationItem.rightBarButtonItem = self.editButtonItem()
		}
		
	}
	
	override func viewWillAppear(animated: Bool) {
		loadInitialData()
		self.tableView.reloadData()
		
	}
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let fileName = (UIApplication.sharedApplication().delegate as! AppDelegate).fileName {
            if let data = (UIApplication.sharedApplication().delegate as! AppDelegate).fileData {
                let sendView = MailSendViewController(nibName: "MailSendViewController", bundle: nil)
                var sendAccount: EmailAccount? = nil
                
                let accountName = NSUserDefaults.standardUserDefaults().stringForKey("standardAccount")
                let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: "EmailAccount")
                var error: NSError?
                var result: [AnyObject]?
				do {
					result = try managedObjectContext!.executeFetchRequest(fetchRequest)
				} catch let error1 as NSError {
					error = error1
					result = nil
				}
                if error != nil {
                    NSLog("%@", error!.description)
                    return
                } else {
                    if let emailAccounts = result {
                        for account in emailAccounts {
                            if (account as! EmailAccount).accountName == accountName {
                                sendAccount = account as? EmailAccount
                                break
                            }
                        }
                        if sendAccount == nil {
                            sendAccount = emailAccounts.first as? EmailAccount
                        }
                    }
                }
                
                if let account = sendAccount {
                    sendView.account = account
                    sendView.attachFile(fileName, data: data, mimetype: getPathExtensionFromString(fileName)!)
                    
                    (UIApplication.sharedApplication().delegate as! AppDelegate).fileName = nil
                    (UIApplication.sharedApplication().delegate as! AppDelegate).fileData = nil
                    
                    self.navigationController?.pushViewController(sendView, animated: true)
                }
            }
        }
        
    }
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - Table view data source
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		
		// Return the number of sections.
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete method implementation.
		// Return the number of rows in the section.
		return self.keysFromCoreData.count
	}
	
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		let cell = tableView.dequeueReusableCellWithIdentifier("ListPrototypCell", forIndexPath: indexPath) as! KeyItemTableViewCell
		
		// Configure the cell...
		
		let keyItem = self.keysFromCoreData[indexPath.row]
		
		// Fill data to labels
		cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
		cell.LabelKeyOwner.text = keyItem.userIDprimary
		cell.LabelMailAddress.text = keyItem.emailAddressPrimary
		cell.LabelKeyID.text = keyItem.keyID
		cell.secKey.image = UIImage(named: "sec_label.png")
		cell.pubKey.image = UIImage(named: "pub_label.png")
		cell.smime.image = UIImage(named: "smime_label.png")
		cell.pgp.image = UIImage(named: "pgp_label.png")
		
		// Set the right lables for the key type
		switch keyItem.keyType {
		case "SMIME":
			cell.pgp.alpha = myOpacity
			cell.smime.alpha = myOpacityFULL
		case "PGP":
			cell.smime.alpha = myOpacity
			cell.pgp.alpha = myOpacityFULL
		default:
			cell.smime.alpha = myOpacity
			cell.pgp.alpha = myOpacity
		}
		
		if keyItem.isSecretKey && keyItem.isPublicKey {
			cell.pubKey.alpha = myOpacityFULL
			cell.secKey.alpha = myOpacityFULL
		} else {
			if keyItem.isSecretKey {
				cell.pubKey.alpha = myOpacity
				cell.secKey.alpha = myOpacityFULL
			}
			
			if keyItem.isPublicKey {
				cell.secKey.alpha = myOpacity
				cell.pubKey.alpha = myOpacityFULL
			}
		}
		
		
		// Set the valid thru bar
		let currentDate = NSDate()
		let calendar = NSCalendar.currentCalendar()
		if keyItem.validThru > currentDate {
			if let sixMonthsAhead = calendar.dateByAddingUnit(.Month, value: 6, toDate: currentDate, options: []) {
			if keyItem.validThru > sixMonthsAhead {
				cell.validIndicator1.image = UIImage(named: "green_indicator.png")
				cell.validIndicator2.image = UIImage(named: "green_indicator.png")
				cell.validIndicator3.image = UIImage(named: "green_indicator.png")
				cell.validIndicator4.image = UIImage(named: "green_indicator.png")
				cell.validIndicator5.image = UIImage(named: "green_indicator.png")
				
			} else {
				cell.validIndicator1.image = UIImage(named: "yellow_indicator.png")
				cell.validIndicator2.image = UIImage(named: "yellow_indicator.png")
				cell.validIndicator3.image = UIImage(named: "yellow_indicator.png")
				cell.validIndicator4.image = UIImage(named: "gray_indicator.png")
				cell.validIndicator5.image = UIImage(named: "gray_indicator.png")
			}
			}
			
		} else {
			cell.validIndicator1.image = UIImage(named: "red_indicator.png")
			cell.validIndicator2.image = UIImage(named: "gray_indicator.png")
			cell.validIndicator3.image = UIImage(named: "gray_indicator.png")
			cell.validIndicator4.image = UIImage(named: "gray_indicator.png")
			cell.validIndicator5.image = UIImage(named: "gray_indicator.png")
		}
		
		
		return cell
	}
	
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let keyItem = self.keysFromCoreData[indexPath.row]
		if self.isInKeySelectionMode {
			self.isInKeySelectionMode = false
			self.receivedFileDelegate?.didFinishWithKeySelection(keyItem)
			self.cancelTapped(self)
			
		} else {
			self.keyDetailVC = KeyDetailTableViewController(nibName: "KeyDetailTableViewController", bundle: nil)
			self.keyDetailVC?.keyItem = keyItem
			self.navigationController?.pushViewController(self.keyDetailVC!, animated: true)
			
			tableView.deselectRowAtIndexPath(indexPath, animated: true)
		}
	}
	
	
	override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		switch editingStyle {
		case .Delete:
			let key = self.keysFromCoreData[indexPath.row]
			// save data to CoreData (respectively deleting data from CoreData)
			let appDel: AppDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate)
			let context: NSManagedObjectContext = appDel.managedObjectContext!
			let fetchRequest = NSFetchRequest(entityName: "Key")
			fetchRequest.predicate = NSPredicate(format: "userIDprimary = %@", key.userIDprimary)
			fetchRequest.predicate = NSPredicate(format: "emailAddressPrimary = %@", key.emailAddressPrimary)
			
			if let fetchResults = (try? appDel.managedObjectContext!.executeFetchRequest(fetchRequest)) as? [NSManagedObject] {
				if fetchResults.count != 0{
					
					let managedObject = fetchResults[0]
					context.deleteObject(managedObject)
				}
				
				do {
					try context.save()
				} catch let error as NSError {
					NSLog("Key \(key.keyID) was not deleted, error: \(error.localizedDescription)")
					return
				}
				
				// key deleted from core data -> delete from tableview
				self.keysFromCoreData.removeAtIndex(indexPath.row)
				self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
			}
		default:
			return
		}
	}
	
	
	private func loadInitialData() {
		
		let appDel: AppDelegate? = UIApplication.sharedApplication().delegate as? AppDelegate
		if let appDelegate = appDel {
			self.managedObjectContext = appDelegate.managedObjectContext!
			let keyFetchRequest = NSFetchRequest(entityName: "Key")
            
            do {
                let fetchedKeysFromCoreData = try managedObjectContext!.executeFetchRequest(keyFetchRequest) as? [Key]
                self.keysFromCoreData = fetchedKeysFromCoreData!
            } catch _ {
                print("Error while trying to fetch keys")
            }
			
			self.keysFromCoreData.sortInPlace({ (key1, key2) -> Bool in
				return key1.userIDprimary < key2.userIDprimary
			})
		}
	}
	
	@IBAction func cancelTapped(sender: AnyObject) {
		self.dismissViewControllerAnimated(true, completion: nil)
	}
	
	@IBAction func menuTapped(sender: AnyObject) {
		self.delegate?.toggleLeftPanel()
	}
}

